package com.autosales.modules.gemini;

import com.autosales.modules.agent.AgentConversationService;
import com.autosales.modules.agent.AgentCostService;
import com.autosales.modules.agent.AgentService;
import com.autosales.modules.agent.TokenQuotaService;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import com.autosales.modules.agent.entity.AgentConversation;
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
 * AgentService backed by Vertex AI Gemini. Selected when
 * {@code agent.provider=gemini} (set by the {@code gcp} Spring profile).
 *
 * <p>B1.1 scope: text-only completion via {@link VertexAiGeminiClient}.
 * Conversation persistence + quota check + cost tracking are wired through
 * the same services as OpenClawAgentService.
 *
 * <p>Out of scope for B1.1 (added in subsequent stages):
 * <ul>
 *   <li>B1.2 — native function calling against the 28-tool catalog</li>
 *   <li>B1.3 — propose / confirm marker pattern wiring</li>
 *   <li>B2 — tool-call audit logging</li>
 * </ul>
 */
@Service
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class GeminiAgentService implements AgentService {

    private static final Logger log = LoggerFactory.getLogger(GeminiAgentService.class);

    private final VertexAiGeminiClient client;
    private final AgentConversationService conversationService;
    private final TokenQuotaService quotaService;
    private final AgentCostService costService;
    private final CurrentUserContext userContext;

    public GeminiAgentService(VertexAiGeminiClient client,
                              AgentConversationService conversationService,
                              TokenQuotaService quotaService,
                              AgentCostService costService,
                              CurrentUserContext userContext) {
        this.client = client;
        this.conversationService = conversationService;
        this.quotaService = quotaService;
        this.costService = costService;
        this.userContext = userContext;
    }

    @Override
    public AgentResponse invoke(AgentRequest request) {
        String model = client.getDisplayModel();

        if (!client.isConfigured()) {
            return new AgentResponse(
                    "The Gemini agent is not configured on this environment. "
                            + "Set GEMINI_PROJECT_ID env var.",
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
            prependUserContext(messages, userContext.current());
            VertexAiGeminiClient.Reply reply = client.complete(messages);
            String text = reply.text();

            int prompt = reply.promptTokens();
            int completion = reply.completionTokens();
            int tokens = prompt + completion;
            log.info("Gemini turn complete: prompt={} completion={} total={} persistent={}",
                    prompt, completion, tokens, persistent);

            if (persistent && conversationId != null) {
                conversationService.appendTurn(conversationId, request.userMessage(), text, tokens, prompt, completion);
            }

            AgentCostService.TurnCost turnCost = costService.computeTurn(prompt, completion);
            AgentResponse.TurnUsage turnUsage = new AgentResponse.TurnUsage(
                    turnCost.promptTokens(), turnCost.completionTokens(), turnCost.totalTokens(),
                    turnCost.inputCost(), turnCost.outputCost(), turnCost.totalCost(),
                    turnCost.currency(), false /* Gemini reports real token counts */);
            return new AgentResponse(text, model, conversationId, turnUsage, null, null);
        } catch (VertexAiGeminiClient.GeminiException e) {
            return new AgentResponse(e.getMessage(), model, conversationId);
        }
    }

    @Override
    public void stream(AgentRequest request, SseEmitter emitter) {
        // B1.1: stream not yet implemented for Gemini. Falls back to invoke()
        // and emits a single delta + done. B1.2 / B2 will replace with native
        // streaming once the function-calling loop lands.
        try {
            AgentResponse resp = invoke(request);
            try {
                emitter.send(SseEmitter.event().name("delta").data(resp.reply() == null ? "" : resp.reply()));
                Map<String, String> done = new LinkedHashMap<>();
                done.put("reply", resp.reply() == null ? "" : resp.reply());
                done.put("conversationId", resp.conversationId() == null ? "" : resp.conversationId());
                done.put("model", resp.model() == null ? "" : resp.model());
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

    private void prependUserContext(List<Map<String, Object>> messages, CurrentUserContext.Snapshot user) {
        if (user == null) return;
        StringBuilder sb = new StringBuilder("User context for this session: id=");
        sb.append(user.getUserId() != null ? user.getUserId() : "anonymous");
        if (user.getRole() != null) sb.append(", role=").append(user.getRole().name());
        if (user.getDealerCode() != null) sb.append(", dealer=").append(user.getDealerCode());
        sb.append(". You are AUTOSALES, a dealer-sales assistant. Reply concisely; use markdown for tables.");

        Map<String, Object> ctx = new LinkedHashMap<>();
        ctx.put("role", "system");
        ctx.put("content", sb.toString());
        messages.add(0, ctx);
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
