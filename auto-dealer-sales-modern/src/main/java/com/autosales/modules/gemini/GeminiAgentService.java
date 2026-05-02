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
 * AgentService backed by Vertex AI Gemini with native function calling.
 *
 * <p>B1.2 scope: full tool-calling agent loop. Gemini receives the
 * 28-tool catalog, autonomously chains tool calls (e.g., {@code get_dealer}
 * → {@code get_stock_summary} → final summary), and returns synthesized
 * text. Tool calls execute against our REST endpoints via
 * {@link com.autosales.modules.chat.ToolExecutor}.
 *
 * <p>Out of scope (subsequent stages):
 * <ul>
 *   <li>B1.3 — propose / confirm marker pattern wiring</li>
 *   <li>B2 — tool-call audit log + admin trace UI</li>
 *   <li>Streaming (Vertex AI supports it; we do non-streaming for now)</li>
 * </ul>
 */
@Service
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class GeminiAgentService implements AgentService {

    private static final Logger log = LoggerFactory.getLogger(GeminiAgentService.class);

    /**
     * System instruction injected on every turn. Gives Gemini its identity,
     * mandate to use tools for facts, and lightweight domain rules. Layered
     * with the per-turn {@code prependUserContext} which adds the current
     * caller's identity + role.
     */
    private static final String SYSTEM_INSTRUCTION = """
            You are AUTOSALES, an AI assistant for automobile dealership operations.

            You have access to tools that query the dealership's database (dealers,
            vehicles, customers, deals, leads, finance applications, stock, warranty,
            recalls, batch jobs). USE THE TOOLS for any factual question — never
            invent data.

            When a user asks about a specific entity (dealer, customer, deal, vehicle),
            call the appropriate get_* or list_* tool first, then answer based on the
            real data. For multi-step questions, chain tool calls as needed.

            Domain rules:
              - Dealer codes look like DLR01-DLR12 (12 dealers)
              - Deal numbers look like D-00000123 or DL01000123
              - VINs are 17 characters
              - Vehicle aging beyond 60 days is a warning signal
              - APR depends on credit tier (Excellent/Good/Fair/Poor)
              - Warranty claims escalate after 14 days unresolved

            Output guidelines:
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

    public GeminiAgentService(VertexAiGeminiClient client,
                              GeminiToolCatalog toolCatalog,
                              AgentConversationService conversationService,
                              TokenQuotaService quotaService,
                              AgentCostService costService,
                              CurrentUserContext userContext) {
        this.client = client;
        this.toolCatalog = toolCatalog;
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
            prependSystemAndUserContext(messages, userContext.current());
            VertexAiGeminiClient.Reply reply = client.complete(messages, toolCatalog.getTools());
            String text = reply.text();

            int prompt = reply.promptTokens();
            int completion = reply.completionTokens();
            int tokens = prompt + completion;
            log.info("Gemini turn complete: prompt={} completion={} total={} toolCalls={} persistent={}",
                    prompt, completion, tokens, reply.toolCalls().size(), persistent);

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
        // B1.2: still non-streaming. We invoke synchronously then emit a single
        // delta + done so the AgentWidget UX path works. Native Gemini streaming
        // (with function-calling deltas) lands in B2 alongside the audit trace.
        try {
            AgentResponse resp = invoke(request);
            try {
                emitter.send(SseEmitter.event().name("delta").data(resp.reply() == null ? "" : resp.reply()));
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
     * Prepends two system messages — the static SYSTEM_INSTRUCTION (identity,
     * tool mandate, domain rules, output guidelines) and a per-call
     * user-context line so Gemini knows who's calling and which dealer they're
     * scoped to. Same pattern as OpenClawAgentService.
     */
    private void prependSystemAndUserContext(List<Map<String, Object>> messages, CurrentUserContext.Snapshot user) {
        Map<String, Object> sys = new LinkedHashMap<>();
        sys.put("role", "system");
        sys.put("content", SYSTEM_INSTRUCTION);
        messages.add(0, sys);

        if (user != null) {
            StringBuilder sb = new StringBuilder("Current caller: id=");
            sb.append(user.getUserId() != null ? user.getUserId() : "anonymous");
            if (user.getRole() != null) sb.append(", role=").append(user.getRole().name());
            if (user.getDealerCode() != null) sb.append(", dealer=").append(user.getDealerCode());
            sb.append(". When the user says 'my dealership' or omits a dealerCode, use this dealer code.");

            Map<String, Object> ctx = new LinkedHashMap<>();
            ctx.put("role", "system");
            ctx.put("content", sb.toString());
            messages.add(1, ctx);
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
