package com.autosales.modules.a2a;

import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.chat.ToolRegistry;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Agent-to-Agent (A2A) discovery card.
 *
 * <p>Publishes {@code /.well-known/agent.json} so other agents (or
 * orchestrators) can discover AUTOSALES, learn what it can do, and how
 * to talk to it. The {@code .well-known} URI follows RFC 8615 — clients
 * GET this path on a host to find the agent metadata.
 *
 * <p>The card advertises:
 * <ul>
 *   <li>Identity — name, version, dealership domain</li>
 *   <li>Endpoint URLs — agent invocation, MCP server, REST API root</li>
 *   <li>Auth scheme — bearer JWT</li>
 *   <li>Skills (read tools) — extracted from the live tool catalog</li>
 *   <li>Action handlers (write tools) — listed but flagged as
 *       propose/confirm-only (an A2A caller cannot directly invoke a
 *       write; it must use the propose flow)</li>
 *   <li>Model — the LLM the agent uses</li>
 *   <li>Roadmap pointers — what's coming next</li>
 * </ul>
 */
@RestController
@RequiredArgsConstructor
public class AgentCardController {

    @Value("${a2a.public-url:}")
    private String publicUrl;

    @Value("${gemini.model:gemini-2.5-flash}")
    private String agentModel;

    private final ToolRegistry toolRegistry;
    private final ActionRegistry actionRegistry;

    @GetMapping(value = "/.well-known/agent.json",
                produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> agentCard() {
        Map<String, Object> card = new LinkedHashMap<>();
        card.put("schema_version", "0.1");
        card.put("name", "AUTOSALES Dealership Agent");
        card.put("description",
                "AI agent for automobile dealership operations — query inventory, "
                + "deals, customers, leads, finance applications, warranty, recalls; "
                + "propose and execute write actions via a propose/confirm/audit safety "
                + "framework. Federated with NHTSA recall data.");
        card.put("version", "1.0.0");
        card.put("vendor", "AUTOSALES");
        card.put("contact", Map.of(
                "url", publicUrl == null ? "" : publicUrl,
                "type", "system"));

        // ----- Endpoints -----
        Map<String, Object> endpoints = new LinkedHashMap<>();
        endpoints.put("invoke", "/api/agent");
        endpoints.put("invoke_method", "POST");
        endpoints.put("invoke_input_schema", Map.of(
                "type", "object",
                "properties", Map.of(
                        "userMessage", Map.of("type", "string"),
                        "conversationId", Map.of("type", "string"))));
        endpoints.put("mcp", "/mcp");
        endpoints.put("mcp_method", "POST (JSON-RPC 2.0) or GET /mcp/tools");
        endpoints.put("rest_api_root", "/api");
        endpoints.put("admin_trace", "/api/admin/agent-trace/{conversationId}");
        endpoints.put("admin_analytics", "/api/admin/agent-analytics");
        card.put("endpoints", endpoints);

        // ----- Auth -----
        card.put("authentication", Map.of(
                "scheme", "Bearer",
                "type", "JWT",
                "obtain_via", "POST /api/auth/login with {userId, password}",
                "header", "Authorization: Bearer <jwt>"));

        // ----- Model -----
        card.put("model", Map.of(
                "provider", "Vertex AI",
                "name", agentModel,
                "function_calling", true,
                "streaming", true));

        // ----- Skills (read tools) -----
        List<Map<String, Object>> skills = new java.util.ArrayList<>();
        java.util.Set<String> writeNames = new java.util.HashSet<>(actionRegistry.names());
        for (Map<String, Object> def : toolRegistry.getToolDefinitions()) {
            @SuppressWarnings("unchecked")
            Map<String, Object> fn = (Map<String, Object>) def.get("function");
            if (fn == null) continue;
            String name = String.valueOf(fn.get("name"));
            if (writeNames.contains(name)) continue; // writes go in their own section
            Map<String, Object> skill = new LinkedHashMap<>();
            skill.put("id", name);
            skill.put("description", fn.get("description"));
            skill.put("input_schema", fn.get("parameters"));
            skill.put("invocation",
                    "POST /api/agent with userMessage referring to this skill, OR call directly via MCP");
            skills.add(skill);
        }
        card.put("skills", skills);

        // ----- Write actions (propose/confirm only — not directly callable) -----
        List<Map<String, Object>> writes = new java.util.ArrayList<>();
        actionRegistry.all().forEach(handler -> {
            Map<String, Object> w = new LinkedHashMap<>();
            w.put("id", handler.toolName());
            w.put("tier", handler.tier().getCode());
            w.put("allowed_roles", handler.allowedRoles().stream()
                    .map(Enum::name).toList());
            w.put("endpoint", handler.endpointDescriptor());
            w.put("reversible", handler.reversible());
            w.put("invocation", "Indirect — agent emits [[PROPOSE]] marker; user confirms");
            writes.add(w);
        });
        card.put("write_actions", Map.of(
                "policy", "Write actions cannot be invoked directly by external agents. "
                        + "They flow through the propose/confirm/audit/undo framework which "
                        + "requires a human-in-the-loop confirmation. External agents may "
                        + "discover them here for orchestration planning, but execution "
                        + "happens through AUTOSALES' UI.",
                "actions", writes));

        // ----- Capabilities -----
        card.put("capabilities", Map.of(
                "tool_use", true,
                "function_calling", true,
                "audit_trail", true,
                "propose_confirm_undo", true,
                "prerequisite_resolution", true,
                "external_data_sources", List.of("NHTSA recalls", "vPIC VIN decode"),
                "analytics_layer", "BigQuery (autosales_analytics)"
        ));

        // ----- Roadmap (cited; not all yet built) -----
        card.put("roadmap", Map.of(
                "bq_dual_duty_replica",
                "Replicate OLTP tables to BigQuery so analysts and the agent share the "
                        + "same query surface; expose a query_data(sql) tool for analytical reads",
                "auto_endpoint_discovery",
                "Auto-generate tool descriptors from all 250+ REST endpoints with semantic "
                        + "retrieval; eliminates hand-curation drift",
                "multi_agent_orchestration",
                "OEM corporate agent fans out queries across 12 dealer agents via this A2A card"
        ));

        // CORS-friendly
        return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(card);
    }
}
