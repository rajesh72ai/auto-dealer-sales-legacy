package com.autosales.modules.gemini;

import com.autosales.modules.agent.AgentConversationService;
import com.autosales.modules.agent.AgentCostService;
import com.autosales.modules.agent.AgentService;
import com.autosales.modules.agent.TokenQuotaService;
import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.agent.action.ActionService;
import com.autosales.modules.agent.action.AgentToolCallAuditService;
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

/**
 * AgentService backed by Vertex AI Gemini with native function calling.
 *
 * <p>B2 scope: full Phase 3 Safe Action Framework wiring on the Gemini path.
 *
 * <ul>
 *   <li><b>Read tools</b> (28-tool catalog minus writes) are exposed to Gemini as
 *       native {@code FunctionDeclaration}s. Gemini calls them autonomously; each
 *       call is persisted to {@code agent_tool_call_audit} with tier={@code R}.</li>
 *   <li><b>Write tools</b> (the 9 {@code ActionHandler} beans: create_lead,
 *       apply_incentive, mark_arrived, etc.) are NOT exposed for function calling.
 *       The system instruction teaches Gemini to emit a
 *       {@code [[PROPOSE]]{toolName, payload}[[/PROPOSE]]} marker at the end of its
 *       reply. The scanner extracts it; we call
 *       {@link ActionService#propose} in-process; the React widget renders a
 *       ProposalCard and the user clicks Execute to commit.</li>
 * </ul>
 *
 * <p>This is the same propose/confirm/commit flow used by
 * {@link com.autosales.modules.agent.OpenClawAgentService} on master — the
 * Phase 3 framework is LLM-agnostic; only the transport of the marker convention
 * needed reinstating for the new model.
 */
@Service
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class GeminiAgentService implements AgentService {

    private static final Logger log = LoggerFactory.getLogger(GeminiAgentService.class);

    /**
     * System instruction injected on every turn. Gives Gemini its identity,
     * tool mandate, the Write-Tool Protocol (propose marker for side-effecting
     * actions), and lightweight domain rules. Layered with the per-turn
     * {@code prependUserContext} which adds the current caller's identity + role.
     */
    private static final String SYSTEM_INSTRUCTION_TEMPLATE = """
            You are AUTOSALES, an AI assistant for automobile dealership operations.

            ## Read tools (function calling)

            You have access to the following read-only tools, which you may call
            via native function calling for any factual question — never invent
            data:

            %READ_TOOLS%

            ### Entity-lookup rule (IMPORTANT)
            When the user names a specific entity (a customer, deal, vehicle, lead,
            warranty claim, dealer, incentive, recall, etc.), ALWAYS call the
            appropriate list_* / get_* / find_* tool to verify the entity exists
            and to retrieve its real data BEFORE responding. NEVER assume an
            entity exists from the user's prose alone, and NEVER respond with
            details about an entity you have not looked up. If the lookup
            returns no match, say so plainly and offer the next step.

            ### Multi-step queries
            Chain tool calls as needed (e.g., list_customers → get_customer →
            list_deals). For compound questions ("what closed today AND
            commissions?"), you may emit multiple function_call parts in one
            response — they will execute in parallel.

            ## Write tools (Write-Tool Protocol — IMPORTANT)

            For these write actions, DO NOT use function calling. Instead, at
            the END of your reply, emit a single block exactly like this:

                [[PROPOSE]]{"toolName":"<name>","payload":{...}}[[/PROPOSE]]

            The user will see a preview card and approve before any database
            change happens. You write the prose explanation BEFORE the marker;
            the marker JSON itself is hidden from the user but is parsed by the
            backend.

            Available write actions and their required role:

            %WRITE_TOOLS%

            If the caller's role does not permit a requested write, politely
            decline and name the role required — do not emit the marker.

            ### Pre-requisites for writes
            Some writes require references to existing entities (e.g.,
            create_lead requires an existing customerId). Always resolve those
            via a read tool first (list_customers / get_customer for customers,
            list_deals / get_deal for deals, list_vehicles / get_vehicle for
            vehicles). If the referenced entity does not exist and there is no
            tool to create it, decline gracefully and tell the user what is
            missing — do not invent ids.

            ## Capability-gap logging (IMPORTANT)

            When a user asks for a capability your tools do NOT support — for
            example a query you cannot answer because no matching read tool
            exists, or a write you cannot perform because no ActionHandler is
            registered — BEFORE declining to the user, call the tool
            log_capability_gap with:
              - description: a one-sentence summary of what the user asked for
              - userMessage: the user's original prompt verbatim
              - severity: "LOW" (cosmetic / nice-to-have), "MEDIUM" (affects a
                workflow but workaround exists), or "HIGH" (blocks a common
                business case)
            Then tell the user honestly that the capability isn't available
            yet, has been logged for the team, and offer the closest workaround
            you can perform. NEVER hallucinate data to fill the gap.

            ## NHTSA federal data (when to use which tool)

            For recall questions:
              - If the user names a SPECIFIC VIN — call nhtsa_recall_lookup(vin)
                to hit the federal NHTSA recallsByVin API. This returns the
                authoritative, live list of campaigns affecting that exact car.
              - For BROAD recall questions (campaigns by make/model, all our
                stored campaigns) — call list_recalls (our local DB).
              - For maximum coverage on a vehicle the dealership owns: call
                BOTH and merge — nhtsa_recall_lookup first for federal data,
                then list_recalls to surface any internal annotations.

            For VIN decoding:
              - decode_vin (our internal heuristic) is fast and good enough for
                routine prefix lookups.
              - nhtsa_vin_decode (vPIC) is the authoritative federal source —
                use when the user asks for canonical / detailed data, or when
                decode_vin returns minimal info.

            ## Domain rules

              - Dealer codes look like DLR01-DLR12 (12 dealers)
              - Deal numbers look like D-00000123 or DL01000123
              - VINs are 17 characters
              - Vehicle aging beyond 60 days is a warning signal
              - APR depends on credit tier (Excellent/Good/Fair/Poor)
              - Warranty claims escalate after 14 days unresolved

            ## Output guidelines

              - Use markdown tables for tabular data
              - Keep responses concise — bullet points over prose
              - When tools return errors, explain clearly and suggest the next step
              - Redact full SSNs to last 4 digits
              - Never expose raw API keys, JWT tokens, or password hashes
            """;

    private final VertexAiGeminiClient client;
    private final GeminiToolCatalog toolCatalog;
    private final AgentConversationService conversationService;
    private final TokenQuotaService quotaService;
    private final AgentCostService costService;
    private final CurrentUserContext userContext;
    private final ActionService actionService;
    private final ActionRegistry actionRegistry;
    private final AgentToolCallAuditService auditService;
    private final ObjectMapper mapper;

    /** Cached system instruction with read/write tool lists baked in. */
    private final String systemInstruction;

    public GeminiAgentService(VertexAiGeminiClient client,
                              GeminiToolCatalog toolCatalog,
                              AgentConversationService conversationService,
                              TokenQuotaService quotaService,
                              AgentCostService costService,
                              CurrentUserContext userContext,
                              ActionService actionService,
                              ActionRegistry actionRegistry,
                              AgentToolCallAuditService auditService,
                              ObjectMapper mapper) {
        this.client = client;
        this.toolCatalog = toolCatalog;
        this.conversationService = conversationService;
        this.quotaService = quotaService;
        this.costService = costService;
        this.userContext = userContext;
        this.actionService = actionService;
        this.actionRegistry = actionRegistry;
        this.auditService = auditService;
        this.mapper = mapper;
        this.systemInstruction = buildSystemInstruction();
    }

    @Override
    public AgentResponse invoke(AgentRequest request) {
        String model = client.getDisplayModel();

        if (!client.isConfigured()) {
            return new AgentResponse(
                    "The Gemini agent is not configured on this environment. Set GEMINI_PROJECT_ID env var.",
                    model, request.conversationId());
        }

        String userId = resolveUserId();
        TokenQuotaService.QuotaCheck quota = quotaService.check(userId);
        if (!quota.allowed()) {
            return new AgentResponse(quota.friendlyRejection(), model, request.conversationId());
        }

        boolean persistent = request.userMessage() != null && !request.userMessage().isBlank();
        String conversationId = request.conversationId();
        List<Map<String, Object>> messages = new ArrayList<>();

        if (persistent) {
            if (conversationId == null || conversationId.isBlank()) {
                AgentConversation created = conversationService.create(userId, null, model, request.userMessage());
                conversationId = created.getConversationId();
            } else {
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
            CurrentUserContext.Snapshot user = userContext.current();
            prependSystemAndUserContext(messages, user);

            // Per-tool-call audit recorder — captures every read function_call Gemini
            // makes inside its agent loop. Closed-over conversationId so each row is
            // properly scoped in the trace UI.
            final String convIdFinal = conversationId;
            VertexAiGeminiClient.ToolCallRecorder recorder = (toolName, args, result, elapsedMs, errored) -> {
                try {
                    auditService.recordReadToolCall(user, convIdFinal, toolName, args, result, elapsedMs, errored);
                } catch (Exception auditErr) {
                    log.warn("Failed to persist read-tool audit for {}: {}", toolName, auditErr.getMessage());
                }
            };

            VertexAiGeminiClient.Reply reply = client.complete(messages, toolCatalog.getTools(), recorder);
            String rawText = reply.text() == null ? "" : reply.text();

            // Extract proposal marker (if any) from the reply and run propose() in-process.
            ProposalMarkerScanner scanner = new ProposalMarkerScanner();
            scanner.onDelta(rawText);
            scanner.flush();
            String text = scanner.cleanedContent();
            ProposalResult proposalResult = maybeRunProposal(scanner, conversationId, user);
            ProposalResponse proposal = proposalResult != null ? proposalResult.proposal() : null;
            String proposalError = (proposalResult != null && proposalResult.hasError())
                    ? proposalResult.error() : null;

            int prompt = reply.promptTokens();
            int completion = reply.completionTokens();
            int tokens = prompt + completion;
            log.info("Gemini turn complete: prompt={} completion={} total={} toolCalls={} persistent={} proposal={}",
                    prompt, completion, tokens, reply.toolCalls().size(), persistent, proposal != null);

            if (persistent && conversationId != null) {
                conversationService.appendTurn(conversationId, request.userMessage(), text, tokens, prompt, completion);
            }

            AgentCostService.TurnCost turnCost = costService.computeTurn(prompt, completion);
            AgentResponse.TurnUsage turnUsage = new AgentResponse.TurnUsage(
                    turnCost.promptTokens(), turnCost.completionTokens(), turnCost.totalTokens(),
                    turnCost.inputCost(), turnCost.outputCost(), turnCost.totalCost(),
                    turnCost.currency(), false /* Gemini reports real token counts */);
            return new AgentResponse(text, model, conversationId, turnUsage, proposal, proposalError);
        } catch (VertexAiGeminiClient.GeminiException e) {
            return new AgentResponse(e.getMessage(), model, conversationId);
        }
    }

    @Override
    public void stream(AgentRequest request, SseEmitter emitter) {
        // B2: still non-streaming on the wire. We invoke synchronously then emit
        // delta + (proposal | proposal-error)? + done — same SSE event surface
        // OpenClawAgentService uses, so the AgentWidget React code is unchanged.
        try {
            AgentResponse resp = invoke(request);
            try {
                emitter.send(SseEmitter.event().name("delta").data(resp.reply() == null ? "" : resp.reply()));
                if (resp.proposal() != null) {
                    emitter.send(SseEmitter.event().name("proposal").data(toJsonString(resp.proposal())));
                } else if (resp.proposalError() != null) {
                    Map<String, String> errPayload = new LinkedHashMap<>();
                    errPayload.put("message", resp.proposalError());
                    emitter.send(SseEmitter.event().name("proposal-error").data(toJsonEscaped(errPayload)));
                }
                Map<String, String> done = new LinkedHashMap<>();
                done.put("reply", resp.reply() == null ? "" : resp.reply());
                done.put("conversationId", resp.conversationId() == null ? "" : resp.conversationId());
                done.put("model", resp.model() == null ? "" : resp.model());
                if (resp.usage() != null) {
                    done.put("promptTokens", String.valueOf(resp.usage().promptTokens()));
                    done.put("completionTokens", String.valueOf(resp.usage().completionTokens()));
                    done.put("totalTokens", String.valueOf(resp.usage().totalTokens()));
                    done.put("totalCost", resp.usage().totalCost() == null ? "0" : resp.usage().totalCost().toPlainString());
                    done.put("currency", resp.usage().currency() == null ? "USD" : resp.usage().currency());
                    done.put("estimated", "false");
                }
                emitter.send(SseEmitter.event().name("done").data(toJsonEscaped(done)));
            } catch (Exception ignore) { /* client disconnected */ }
            emitter.complete();
        } catch (Exception e) {
            log.warn("Gemini stream failed", e);
            try {
                emitter.send(SseEmitter.event().name("error").data("Agent error: " + e.getMessage()));
            } catch (Exception ignore) { }
            emitter.complete();
        }
    }

    @Override
    public boolean isAvailable() {
        return client.isConfigured();
    }

    @Override
    public String getModel() {
        return client.getDisplayModel();
    }

    private String resolveUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getName() != null) return auth.getName();
        return "anonymous";
    }

    /**
     * Builds the system instruction with the live read-tool list and write-tool
     * roles baked in. Done once at construction; tool catalogs do not change at
     * runtime.
     */
    private String buildSystemInstruction() {
        String readToolList = String.join(", ", toolCatalog.getReadToolNames());
        StringBuilder writeList = new StringBuilder();
        actionRegistry.all().forEach(handler -> {
            writeList.append("  - ").append(handler.toolName())
                    .append(" (tier=").append(handler.tier().getCode())
                    .append(", roles=");
            if (handler.allowedRoles() != null && !handler.allowedRoles().isEmpty()) {
                handler.allowedRoles().forEach(r -> writeList.append(r.name()).append("/"));
                writeList.setLength(writeList.length() - 1);
            } else {
                writeList.append("any");
            }
            writeList.append(") — ").append(handler.endpointDescriptor()).append("\n");
        });
        return SYSTEM_INSTRUCTION_TEMPLATE
                .replace("%READ_TOOLS%", readToolList.isBlank() ? "(none registered)" : readToolList)
                .replace("%WRITE_TOOLS%", writeList.length() == 0 ? "  (none registered)" : writeList.toString());
    }

    /**
     * Prepends two system messages — the static system instruction (identity,
     * tool mandate, Write-Tool Protocol, domain rules) and a per-call
     * user-context line so Gemini knows who's calling and which dealer they're
     * scoped to. Same pattern as OpenClawAgentService.
     */
    private void prependSystemAndUserContext(List<Map<String, Object>> messages, CurrentUserContext.Snapshot user) {
        Map<String, Object> sys = new LinkedHashMap<>();
        sys.put("role", "system");
        sys.put("content", systemInstruction);
        messages.add(0, sys);

        if (user != null) {
            StringBuilder sb = new StringBuilder("Current caller: id=");
            sb.append(user.getUserId() != null ? user.getUserId() : "anonymous");
            if (user.getRole() != null) sb.append(", role=").append(user.getRole().name());
            if (user.getDealerCode() != null) sb.append(", dealer=").append(user.getDealerCode());
            sb.append(". When the user says 'my dealership' or omits a dealerCode, use this dealer code.");
            sb.append(" Enforce the Write-Tool Protocol role gates above; if the caller's role isn't permitted for the requested write, decline and name the role required.");

            Map<String, Object> ctx = new LinkedHashMap<>();
            ctx.put("role", "system");
            ctx.put("content", sb.toString());
            messages.add(1, ctx);
        }
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
    private ProposalResult maybeRunProposal(ProposalMarkerScanner scanner,
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
