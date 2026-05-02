package com.autosales.modules.agent;

import com.autosales.modules.agent.dto.AgentRequest;
import com.autosales.modules.agent.dto.AgentResponse;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * Strategy interface for the AI Agent backend. Two implementations:
 *
 * <ul>
 *   <li>{@link OpenClawAgentService} — wraps the OpenClaw gateway + Claude.
 *       Default; selected when {@code agent.provider=openclaw} (or unset).
 *       Used by the local docker-compose stack on master.</li>
 *   <li>{@link com.autosales.modules.gemini.GeminiAgentService} — calls
 *       Vertex AI Gemini directly with native function calling. Selected
 *       when {@code agent.provider=gemini}. Used on the GCP deployment
 *       (Phase B onwards).</li>
 * </ul>
 *
 * <p>The Phase 3 Safe Action Framework (propose / confirm / commit / undo)
 * is LLM-agnostic and lives outside this interface — both implementations
 * delegate to {@code ActionService} for write actions.
 */
public interface AgentService {

    /**
     * Run a single agent turn synchronously and return the full response.
     * Used by clients that don't support streaming (and by the
     * {@code /api/agent} POST endpoint).
     */
    AgentResponse invoke(AgentRequest request);

    /**
     * Run a single agent turn and stream the response via SSE. Emits
     * {@code delta}, {@code proposal}, {@code proposal-error}, {@code done},
     * and {@code error} events.
     */
    void stream(AgentRequest request, SseEmitter emitter);

    /** Whether the agent is configured and healthy on this environment. */
    boolean isAvailable();

    /** Human-readable model identifier for UI display (e.g. {@code anthropic/claude-sonnet-4-6}, {@code google/gemini-2.5-flash}). */
    String getModel();
}
