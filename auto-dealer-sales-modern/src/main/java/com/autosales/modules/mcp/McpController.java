package com.autosales.modules.mcp;

import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.chat.ToolExecutor;
import com.autosales.modules.chat.ToolRegistry;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Model Context Protocol (MCP) over HTTP server.
 *
 * <p>Exposes the AUTOSALES read-tool catalog (~28 tools) as MCP-discoverable
 * primitives so any MCP client — Claude Desktop, IDE assistants, custom
 * orchestrators — can drive the dealership system without going through our
 * React UI or direct REST. The same {@link ToolRegistry} that feeds the
 * Gemini agent's function declarations feeds this surface; tools defined
 * once, consumed by many.
 *
 * <p><b>Read vs. write:</b> only read tools are exposed via MCP. Write
 * tools (the 9 {@link com.autosales.modules.agent.action.ActionHandler}
 * beans) require the propose/confirm/audit framework which has no MCP
 * primitive — exposing them here would bypass the safety properties.
 * MCP clients that ask for the write surface get an explanatory rejection.
 *
 * <p><b>Protocol shape:</b> we support both
 * <ul>
 *   <li>The MCP-over-HTTP JSON-RPC 2.0 envelope at {@code POST /mcp} with
 *       methods {@code initialize}, {@code tools/list}, {@code tools/call} —
 *       this is what real MCP clients speak.</li>
 *   <li>Convenience REST endpoints at {@code GET /mcp/tools} and
 *       {@code POST /mcp/tools/{name}} — handy for curl, smoke tests,
 *       and human inspection.</li>
 * </ul>
 *
 * <p><b>Auth:</b> piggybacks on the same Spring Security chain as the rest
 * of the API. MCP clients pass the same JWT (or API key) they'd use for
 * any other endpoint. No separate MCP auth layer.
 */
@RestController
@RequestMapping("/mcp")
@RequiredArgsConstructor
public class McpController {

    private static final Logger log = LoggerFactory.getLogger(McpController.class);
    private static final String PROTOCOL_VERSION = "2024-11-05";
    private static final String SERVER_NAME = "AUTOSALES";
    private static final String SERVER_VERSION = "1.0.0";

    private final ToolRegistry toolRegistry;
    private final ActionRegistry actionRegistry;
    private final ToolExecutor toolExecutor;

    // ---------- JSON-RPC 2.0 envelope (what real MCP clients speak) ----------

    @PostMapping(value = "", consumes = MediaType.APPLICATION_JSON_VALUE,
                          produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> jsonRpc(@RequestBody Map<String, Object> req) {
        Object id = req.get("id");
        String method = String.valueOf(req.get("method"));
        @SuppressWarnings("unchecked")
        Map<String, Object> params = req.get("params") instanceof Map<?, ?>
                ? (Map<String, Object>) req.get("params")
                : Map.of();

        try {
            Map<String, Object> result = switch (method) {
                case "initialize" -> handleInitialize(params);
                case "tools/list" -> handleToolsList();
                case "tools/call" -> handleToolsCall(params);
                case "notifications/initialized" -> Map.of(); // no-op ack
                default -> throw new IllegalArgumentException("Method not supported: " + method);
            };
            return ResponseEntity.ok(jsonRpcSuccess(id, result));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.ok(jsonRpcError(id, -32601, ex.getMessage()));
        } catch (SecurityException ex) {
            return ResponseEntity.ok(jsonRpcError(id, -32000, ex.getMessage()));
        } catch (Exception ex) {
            log.warn("MCP call failed: method={}, error={}", method, ex.getMessage());
            return ResponseEntity.ok(jsonRpcError(id, -32603, "Internal error: " + ex.getMessage()));
        }
    }

    // ---------- Convenience REST endpoints (for curl / smoke / humans) ----------

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> info() {
        return ResponseEntity.ok(Map.of(
                "protocolVersion", PROTOCOL_VERSION,
                "serverInfo", Map.of("name", SERVER_NAME, "version", SERVER_VERSION),
                "capabilities", Map.of("tools", Map.of()),
                "transport", "http+json-rpc",
                "endpoint", "POST /mcp",
                "tools_count", listExposedTools().size(),
                "writes_excluded", actionRegistry.names()
        ));
    }

    @GetMapping("/tools")
    public ResponseEntity<Map<String, Object>> listToolsRest() {
        return ResponseEntity.ok(handleToolsList());
    }

    @PostMapping(value = "/tools/{name}",
                 consumes = MediaType.APPLICATION_JSON_VALUE,
                 produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> callToolRest(
            @org.springframework.web.bind.annotation.PathVariable String name,
            @RequestBody(required = false) Map<String, Object> arguments) {
        Map<String, Object> params = new LinkedHashMap<>();
        params.put("name", name);
        params.put("arguments", arguments != null ? arguments : Map.of());
        return ResponseEntity.ok(handleToolsCall(params));
    }

    // ---------- handlers ----------

    private Map<String, Object> handleInitialize(Map<String, Object> params) {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("protocolVersion", PROTOCOL_VERSION);
        info.put("serverInfo", Map.of("name", SERVER_NAME, "version", SERVER_VERSION));
        info.put("capabilities", Map.of("tools", Map.of("listChanged", false)));
        info.put("instructions",
                "AUTOSALES dealership system — read-only tool surface for MCP clients. "
                + "Write actions are NOT exposed via MCP; they go through the propose/confirm "
                + "framework available in the AUTOSALES UI. " + listExposedTools().size()
                + " read tools available; call tools/list to enumerate.");
        return info;
    }

    private Map<String, Object> handleToolsList() {
        List<Map<String, Object>> tools = new java.util.ArrayList<>();
        for (Map<String, Object> def : listExposedTools()) {
            @SuppressWarnings("unchecked")
            Map<String, Object> fn = (Map<String, Object>) def.get("function");
            if (fn == null) continue;
            Map<String, Object> tool = new LinkedHashMap<>();
            tool.put("name", fn.get("name"));
            tool.put("description", fn.get("description"));
            tool.put("inputSchema", fn.get("parameters"));
            tools.add(tool);
        }
        return Map.of("tools", tools);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> handleToolsCall(Map<String, Object> params) {
        String name = String.valueOf(params.get("name"));
        Object argsObj = params.get("arguments");
        Map<String, Object> args = argsObj instanceof Map ? (Map<String, Object>) argsObj : Map.of();

        // Block write tools — MCP has no propose/confirm primitive.
        if (actionRegistry.names().contains(name)) {
            throw new SecurityException(
                    "Tool '" + name + "' is a write action; MCP clients cannot invoke it directly. "
                    + "Use the AUTOSALES UI's propose/confirm flow to execute write actions.");
        }
        // Verify the tool is in our catalog before delegating to the executor.
        Set<String> known = listExposedToolNames();
        if (!known.contains(name)) {
            throw new IllegalArgumentException("Unknown tool: " + name);
        }

        long started = System.currentTimeMillis();
        String resultText = toolExecutor.execute(name, args);
        long elapsed = System.currentTimeMillis() - started;
        log.info("MCP tools/call: {} ({}ms)", name, elapsed);

        // MCP tools/call result shape: { content: [ { type: "text", text: "..." } ] }
        Map<String, Object> content = new LinkedHashMap<>();
        content.put("type", "text");
        content.put("text", resultText);
        return Map.of("content", List.of(content), "isError", false);
    }

    // ---------- helpers ----------

    private List<Map<String, Object>> listExposedTools() {
        // Reuse ToolRegistry's full catalog but filter out write actions.
        Set<String> writes = Set.copyOf(actionRegistry.names());
        return toolRegistry.getToolDefinitions().stream()
                .filter(def -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> fn = (Map<String, Object>) def.get("function");
                    String name = fn != null ? String.valueOf(fn.get("name")) : null;
                    return name != null && !writes.contains(name);
                })
                .toList();
    }

    private Set<String> listExposedToolNames() {
        return listExposedTools().stream()
                .map(def -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> fn = (Map<String, Object>) def.get("function");
                    return fn != null ? String.valueOf(fn.get("name")) : null;
                })
                .filter(java.util.Objects::nonNull)
                .collect(java.util.stream.Collectors.toCollection(java.util.LinkedHashSet::new));
    }

    private static Map<String, Object> jsonRpcSuccess(Object id, Map<String, Object> result) {
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("jsonrpc", "2.0");
        resp.put("id", id);
        resp.put("result", result);
        return resp;
    }

    private static Map<String, Object> jsonRpcError(Object id, int code, String message) {
        Map<String, Object> err = new LinkedHashMap<>();
        err.put("code", code);
        err.put("message", message);
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("jsonrpc", "2.0");
        resp.put("id", id);
        resp.put("error", err);
        return resp;
    }
}
