package com.autosales.modules.agent;

import com.autosales.modules.agent.action.ActionService;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.ProposalMarkerScanner;
import com.autosales.modules.agent.action.dto.ProposalResponse;
import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import com.autosales.modules.agent.entity.AgentConversation;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * AgentService implementation backed by the OpenClaw gateway + Claude.
 * Selected by default ({@code agent.provider=openclaw} or unset). Used by
 * the local docker-compose stack on master.
 *
 * <p>Renamed from the previous concrete {@code AgentService} class as part
 * of Phase B (multi-LLM support). All internal logic — propose marker
 * scanner, in-process proposal flow, user context prepending, token
 * estimation fallback — is unchanged.
 */
@Service
@ConditionalOnProperty(name = "agent.provider", havingValue = "openclaw", matchIfMissing = true)
public class OpenClawAgentService implements AgentService {

    private static final Logger log = LoggerFactory.getLogger(OpenClawAgentService.class);

    private final OpenClawClient openClawClient;
    private final OpenClawStreamClient streamClient;
    private final AgentConversationService conversationService;
    private final TokenQuotaService quotaService;
    private final AgentCostService costService;
    private final ActionService actionService;
    private final CurrentUserContext userContext;
    private final ObjectMapper mapper;
    private final ExecutorService streamExecutor = Executors.newCachedThreadPool();

    public OpenClawAgentService(OpenClawClient openClawClient,
                                OpenClawStreamClient streamClient,
                                AgentConversationService conversationService,
                                TokenQuotaService quotaService,
                                AgentCostService costService,
                                ActionService actionService,
                                CurrentUserContext userContext,
                                ObjectMapper mapper) {
        this.openClawClient = openClawClient;
        this.streamClient = streamClient;
        this.conversationService = conversationService;
        this.quotaService = quotaService;
        this.costService = costService;
        this.actionService = actionService;
        this.userContext = userContext;
        this.mapper = mapper;
    }

    // Anthropic averages ~3.5 chars/token for English. We use 4 (slightly
    // conservative) as a fallback when OpenClaw reports usage as 0 — its
    // OpenAI-compat shim doesn't propagate Anthropic's real token counts.
    private static final double CHARS_PER_TOKEN = 4.0;

    private static int estimateTokens(String text) {
        if (text == null || text.isEmpty()) return 0;
        return Math.max(1, (int) Math.ceil(text.length() / CHARS_PER_TOKEN));
    }

    private static int estimateMessagesTokens(List<Map<String, Object>> messages) {
        int total = 0;
        for (Map<String, Object> m : messages) {
            Object content = m.get("content");
            if (content != null) total += estimateTokens(content.toString());
        }
        return total;
    }

    @Override
    public AgentResponse invoke(AgentRequest request) {
        String model = openClawClient.getModel();

        if (!openClawClient.isConfigured()) {
            return new AgentResponse(
                    "The AI Agent is not configured on this environment. Please contact your administrator.",
                    model,
                    request.conversationId()
            );
        }

        String userId = resolveUserId();
        TokenQuotaService.QuotaCheck quota = quotaService.check(userId);
        if (!quota.allowed()) {
            return new AgentResponse(quota.friendlyRejection(), model, request.conversationId());
        }

        // Determine mode
        boolean persistent = request.userMessage() != null && !request.userMessage().isBlank();
        String conversationId = request.conversationId();
        List<Map<String, Object>> messages = new ArrayList<>();

        if (persistent) {
            if (conversationId == null || conversationId.isBlank()) {
                AgentConversation created = conversationService.create(userId, null, model, request.userMessage());
                conversationId = created.getConversationId();
            } else {
                // Verify ownership (simple: same userId)
                Optional<AgentConversation> existing = conversationService.findById(conversationId);
                if (existing.isPresent() && !existing.get().getUserId().equals(userId)) {
                    return new AgentResponse("Conversation not found.", model, null);
                }
                messages.addAll(conversationService.loadReplayMessages(conversationId));
            }
            Map<String, Object> userEntry = new LinkedHashMap<>();
            userEntry.put("role", "user");
            userEntry.put("content", request.userMessage());
            messages.add(userEntry);
        } else if (request.messages() != null) {
            for (AgentRequest.Message msg : request.messages()) {
                Map<String, Object> entry = new LinkedHashMap<>();
                entry.put("role", msg.role());
                entry.put("content", msg.content());
                messages.add(entry);
            }
        }

        try {
            prependUserContext(messages, userContext.current());
            OpenClawClient.CompletionResponse response = openClawClient.complete(messages);
            if (response == null || response.choices() == null || response.choices().isEmpty()) {
                return new AgentResponse("The agent returned no response.", model, conversationId);
            }

            String rawReply = response.choices().get(0).message().content();
            if (rawReply == null) rawReply = "";

            // Extract proposal marker (if any) from the reply and run propose() in-process.
            ProposalMarkerScanner scanner = new ProposalMarkerScanner();
            scanner.onDelta(rawReply);
            scanner.flush();
            String reply = scanner.cleanedContent();
            ProposalResult proposalResult = maybeRunProposal(scanner, conversationId);
            ProposalResponse proposal = proposalResult != null ? proposalResult.proposal() : null;

            OpenClawClient.Usage usage = response.usage();
            Integer prompt = usage != null && usage.promptTokens() > 0 ? usage.promptTokens() : null;
            Integer completion = usage != null && usage.completionTokens() > 0 ? usage.completionTokens() : null;
            boolean estimated = false;
            if (prompt == null) {
                prompt = estimateMessagesTokens(messages);
                estimated = true;
            }
            if (completion == null) {
                completion = estimateTokens(reply);
                estimated = true;
            }
            int tokens = prompt + completion;
            log.info("Agent turn complete: prompt={} completion={} total={} estimated={} persistent={} proposal={}",
                    prompt, completion, tokens, estimated, persistent, proposal != null);

            if (persistent) {
                conversationService.appendTurn(conversationId, request.userMessage(), reply, tokens, prompt, completion);
            }

            AgentCostService.TurnCost turnCost = costService.computeTurn(prompt, completion);
            AgentResponse.TurnUsage turnUsage = new AgentResponse.TurnUsage(
                    turnCost.promptTokens(), turnCost.completionTokens(), turnCost.totalTokens(),
                    turnCost.inputCost(), turnCost.outputCost(), turnCost.totalCost(),
                    turnCost.currency(), estimated);
            String proposalError = (proposalResult != null && proposalResult.hasError())
                    ? proposalResult.error() : null;
            return new AgentResponse(reply, model, conversationId, turnUsage, proposal, proposalError);
        } catch (OpenClawClient.AgentException e) {
            return new AgentResponse(e.getMessage(), model, conversationId);
        }
    }

    /**
     * Stream a response. Emits SSE events of type "delta" (content fragments) and
     * finally "done" (with final text and conversationId).
     */
    @Override
    public void stream(AgentRequest request, SseEmitter emitter) {
        String model = openClawClient.getModel();

        if (!streamClient.isConfigured()) {
            emitEvent(emitter, "error", "The AI Agent is not configured on this environment.");
            emitter.complete();
            return;
        }

        String userId = resolveUserId();
        TokenQuotaService.QuotaCheck quota = quotaService.check(userId);
        if (!quota.allowed()) {
            emitEvent(emitter, "error", quota.friendlyRejection());
            emitter.complete();
            return;
        }

        boolean persistent = request.userMessage() != null && !request.userMessage().isBlank();
        final String[] conversationIdHolder = { request.conversationId() };
        List<Map<String, Object>> messages = new ArrayList<>();

        try {
            if (persistent) {
                if (conversationIdHolder[0] == null || conversationIdHolder[0].isBlank()) {
                    AgentConversation created = conversationService.create(userId, null, model, request.userMessage());
                    conversationIdHolder[0] = created.getConversationId();
                    emitEvent(emitter, "conversation", created.getConversationId());
                } else {
                    Optional<AgentConversation> existing = conversationService.findById(conversationIdHolder[0]);
                    if (existing.isPresent() && !existing.get().getUserId().equals(userId)) {
                        emitEvent(emitter, "error", "Conversation not found.");
                        emitter.complete();
                        return;
                    }
                    messages.addAll(conversationService.loadReplayMessages(conversationIdHolder[0]));
                }
                Map<String, Object> userEntry = new LinkedHashMap<>();
                userEntry.put("role", "user");
                userEntry.put("content", request.userMessage());
                messages.add(userEntry);
            } else if (request.messages() != null) {
                for (AgentRequest.Message msg : request.messages()) {
                    Map<String, Object> entry = new LinkedHashMap<>();
                    entry.put("role", msg.role());
                    entry.put("content", msg.content());
                    messages.add(entry);
                }
            }
        } catch (Exception setupErr) {
            emitEvent(emitter, "error", "Agent setup failed: " + setupErr.getMessage());
            emitter.complete();
            return;
        }

        final String finalConvId = conversationIdHolder[0];
        final boolean finalPersistent = persistent;
        final CurrentUserContext.Snapshot userSnap = userContext.current();
        prependUserContext(messages, userSnap);

        CompletableFuture.runAsync(() -> {
            ProposalMarkerScanner scanner = new ProposalMarkerScanner();
            int[] usageTokens = { 0, 0, 0 }; // prompt, completion, total
            try {
                emitEvent(emitter, "status", "Planning and running tools…");
                streamClient.streamCompletion(messages, event -> {
                    switch (event.type()) {
                        case "delta" -> {
                            String visible = scanner.onDelta(event.data());
                            if (!visible.isEmpty()) emitEvent(emitter, "delta", visible);
                        }
                        case "finish" -> emitEvent(emitter, "finish", event.data());
                        case "usage" -> {
                            String[] parts = event.data().split(",");
                            if (parts.length == 3) {
                                try {
                                    usageTokens[0] = Integer.parseInt(parts[0]);
                                    usageTokens[1] = Integer.parseInt(parts[1]);
                                    usageTokens[2] = Integer.parseInt(parts[2]);
                                } catch (NumberFormatException ignore) { }
                            }
                        }
                        default -> { /* ignore */ }
                    }
                });
                String trailing = scanner.flush();
                if (!trailing.isEmpty()) emitEvent(emitter, "delta", trailing);

                ProposalResult proposalResult = maybeRunProposalWithUser(scanner, finalConvId, userSnap);
                if (proposalResult != null) {
                    if (proposalResult.hasError()) {
                        Map<String, String> errPayload = new LinkedHashMap<>();
                        errPayload.put("message", proposalResult.error());
                        emitEvent(emitter, "proposal-error", toJsonEscaped(errPayload));
                    } else if (proposalResult.proposal() != null) {
                        emitEvent(emitter, "proposal", toJsonString(proposalResult.proposal()));
                    }
                }

                String finalReply = scanner.cleanedContent();
                int promptTok = usageTokens[0];
                int completionTok = usageTokens[1];
                boolean estimated = false;
                if (promptTok <= 0) { promptTok = estimateMessagesTokens(messages); estimated = true; }
                if (completionTok <= 0) { completionTok = estimateTokens(finalReply); estimated = true; }
                int totalTok = promptTok + completionTok;
                if (finalPersistent && finalConvId != null) {
                    conversationService.appendTurn(
                            finalConvId,
                            request.userMessage(),
                            finalReply,
                            totalTok,
                            promptTok,
                            completionTok);
                }
                log.info("Agent stream complete: tokens prompt={} completion={} total={} estimated={}",
                        promptTok, completionTok, totalTok, estimated);
                AgentCostService.TurnCost turnCost = costService.computeTurn(promptTok, completionTok);
                Map<String, String> donePayload = new LinkedHashMap<>();
                donePayload.put("reply", finalReply);
                donePayload.put("conversationId", finalConvId == null ? "" : finalConvId);
                donePayload.put("model", model);
                donePayload.put("promptTokens", String.valueOf(turnCost.promptTokens()));
                donePayload.put("completionTokens", String.valueOf(turnCost.completionTokens()));
                donePayload.put("totalTokens", String.valueOf(turnCost.totalTokens()));
                donePayload.put("inputCost", turnCost.inputCost().toPlainString());
                donePayload.put("outputCost", turnCost.outputCost().toPlainString());
                donePayload.put("totalCost", turnCost.totalCost().toPlainString());
                donePayload.put("currency", turnCost.currency());
                donePayload.put("estimated", String.valueOf(estimated));
                emitEvent(emitter, "done", toJsonEscaped(donePayload));
                emitter.complete();
            } catch (Exception e) {
                log.warn("Agent stream failed", e);
                emitEvent(emitter, "error", "Agent error: " + e.getMessage());
                emitter.complete();
            }
        }, streamExecutor);
    }

    @Override
    public boolean isAvailable() {
        return openClawClient.isConfigured();
    }

    @Override
    public String getModel() {
        return openClawClient.getModel();
    }

    private void emitEvent(SseEmitter emitter, String name, String data) {
        try {
            emitter.send(SseEmitter.event().name(name).data(data));
        } catch (Exception ignore) {
            // client disconnected — emitter will be cleaned up on next call
        }
    }

    private String resolveUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getName() != null) return auth.getName();
        return "anonymous";
    }

    private ProposalResult maybeRunProposal(ProposalMarkerScanner scanner, String conversationId) {
        return maybeRunProposalWithUser(scanner, conversationId, userContext.current());
    }

    /**
     * Prepends a synthetic system message with the current caller's role +
     * dealer so Claude can enforce the Tier B role gates in the Write-Tool
     * Protocol. Without this, Claude would not know who is calling and might
     * propose manager-only actions for salespeople, forcing the backend to
     * refuse downstream.
     */
    private void prependUserContext(List<Map<String, Object>> messages, CurrentUserContext.Snapshot user) {
        if (user == null) return;
        StringBuilder sb = new StringBuilder("User context for this session: id=");
        sb.append(user.getUserId() != null ? user.getUserId() : "anonymous");
        if (user.getRole() != null) sb.append(", role=").append(user.getRole().name());
        if (user.getDealerCode() != null) sb.append(", dealer=").append(user.getDealerCode());
        sb.append(". Enforce the Write-Tool Protocol role gates: Tier A allowed for SALESPERSON, MANAGER, ADMIN, FINANCE, CLERK, OPERATOR; Tier B requires MANAGER or ADMIN (close_warranty_claim also allows FINANCE; mark_arrived also allows OPERATOR). If the user's role does not match, politely decline and name the required role.");

        Map<String, Object> ctx = new LinkedHashMap<>();
        ctx.put("role", "system");
        ctx.put("content", sb.toString());
        messages.add(0, ctx);
    }

    /**
     * Result of a proposal attempt — either a successful proposal or an error message.
     */
    record ProposalResult(ProposalResponse proposal, String error) {
        static ProposalResult success(ProposalResponse p) { return new ProposalResult(p, null); }
        static ProposalResult failure(String msg) { return new ProposalResult(null, msg); }
        boolean hasError() { return error != null; }
    }

    @SuppressWarnings("unchecked")
    private ProposalResult maybeRunProposalWithUser(ProposalMarkerScanner scanner,
                                                      String conversationId,
                                                      CurrentUserContext.Snapshot user) {
        if (!scanner.hasProposal()) return null;
        try {
            Map<String, Object> envelope = mapper.readValue(scanner.extractedJson(),
                    new TypeReference<Map<String, Object>>() {});
            String toolName = (String) envelope.get("toolName");
            if (toolName == null || toolName.isBlank()) {
                log.warn("Proposal block missing toolName: {}", scanner.extractedJson());
                return null;
            }
            Object rawPayload = envelope.get("payload");
            Map<String, Object> payload = (rawPayload instanceof Map)
                    ? (Map<String, Object>) rawPayload
                    : Map.of();
            ProposalResponse resp = actionService.propose(user, toolName, payload, conversationId);
            return ProposalResult.success(resp);
        } catch (Exception e) {
            log.warn("Proposal failed (will emit proposal-error): {}", e.getMessage());
            return ProposalResult.failure(e.getMessage());
        }
    }

    private String toJsonString(Object o) {
        try {
            return mapper.writeValueAsString(o);
        } catch (Exception e) {
            return "{}";
        }
    }

    private String toJsonEscaped(Map<String, String> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, String> e : map.entrySet()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("\"").append(e.getKey()).append("\":\"")
              .append(e.getValue()
                      .replace("\\", "\\\\")
                      .replace("\"", "\\\"")
                      .replace("\n", "\\n")
                      .replace("\r", "\\r")
                      .replace("\t", "\\t"))
              .append("\"");
        }
        sb.append("}");
        return sb.toString();
    }
}
