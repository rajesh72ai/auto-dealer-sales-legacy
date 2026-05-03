package com.autosales.modules.discovery;

import com.autosales.modules.agent.action.ActionRegistry;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.lang.reflect.Parameter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Walks {@code RequestMappingHandlerMapping} at startup and produces an
 * {@link AutoToolDescriptor} for every {@code @RestController} method in
 * the application. Drives three consumers from one source of truth:
 *
 * <ol>
 *   <li><b>The agent</b> — keyword retrieval picks top-K matching
 *       descriptors per turn (B-discovery)</li>
 *   <li><b>Support engineers</b> — searchable application documentation
 *       at {@code /admin/api-docs} (B-docs)</li>
 *   <li><b>Admins</b> — governance view to inspect safety levels,
 *       confirm AGENT_NO blocking on dangerous endpoints</li>
 * </ol>
 *
 * <p><b>Safety classification</b> applies path-prefix rules at extraction
 * time. The user can refine these later via per-endpoint overrides
 * (post-meeting work).
 */
@Component
@RequiredArgsConstructor
public class ToolDescriptorExtractor {

    private static final Logger log = LoggerFactory.getLogger(ToolDescriptorExtractor.class);

    private final ApplicationContext context;
    private final ActionRegistry actionRegistry;

    private final List<AutoToolDescriptor> catalog = new ArrayList<>();

    @PostConstruct
    void extract() {
        Map<String, RequestMappingHandlerMapping> beans =
                context.getBeansOfType(RequestMappingHandlerMapping.class);
        Set<String> writeToolNames = Set.copyOf(actionRegistry.names());

        for (RequestMappingHandlerMapping mapping : beans.values()) {
            mapping.getHandlerMethods().forEach((info, handler) -> {
                Set<String> patterns = info.getPathPatternsCondition() != null
                        ? info.getPathPatternsCondition().getPatternValues()
                        : (info.getPatternsCondition() != null
                                ? info.getPatternsCondition().getPatterns()
                                : Set.of());
                Set<org.springframework.web.bind.annotation.RequestMethod> methods =
                        info.getMethodsCondition().getMethods();
                if (methods.isEmpty()) {
                    methods = Set.of(org.springframework.web.bind.annotation.RequestMethod.GET);
                }

                for (String path : patterns) {
                    for (var method : methods) {
                        AutoToolDescriptor d = build(handler, path, method.name(), writeToolNames);
                        if (d != null) catalog.add(d);
                    }
                }
            });
        }

        // Sort: by path then verb, for stable rendering
        catalog.sort((a, b) -> {
            int pc = a.getPath().compareTo(b.getPath());
            return pc != 0 ? pc : a.getHttpMethod().compareTo(b.getHttpMethod());
        });
        log.info("ToolDescriptorExtractor: extracted {} REST endpoint descriptors across {} controllers",
                catalog.size(),
                catalog.stream().map(AutoToolDescriptor::getController).distinct().count());
    }

    /** Returns an immutable snapshot of the extracted catalog. */
    public List<AutoToolDescriptor> getCatalog() {
        return List.copyOf(catalog);
    }

    /**
     * Group descriptors by inferred module — derived from controller class
     * name (e.g. {@code DealerController} → "Dealer Admin"). The result is
     * a sorted map (TreeMap) so rendering order is deterministic.
     */
    public Map<String, List<AutoToolDescriptor>> getByModule() {
        Map<String, List<AutoToolDescriptor>> out = new TreeMap<>();
        for (AutoToolDescriptor d : catalog) {
            out.computeIfAbsent(deriveModule(d.getController()), k -> new ArrayList<>()).add(d);
        }
        return out;
    }

    /** Total counts by safety level — useful for the deck slide and dashboard. */
    public Map<String, Long> getCountsByLevel() {
        Map<String, Long> counts = new LinkedHashMap<>();
        for (String level : List.of("PUBLIC_READ","INTERNAL_READ","WRITE_VIA_PROPOSE","WRITE","ADMIN_ONLY","AGENT_NO")) {
            counts.put(level, catalog.stream().filter(d -> level.equals(d.getSafetyLevel())).count());
        }
        return counts;
    }

    // ---------- internals ----------

    private AutoToolDescriptor build(HandlerMethod handler, String path, String verb, Set<String> writeToolNames) {
        if (!path.startsWith("/api/")
                && !path.startsWith("/mcp")
                && !path.startsWith("/.well-known/")
                && !path.startsWith("/actuator/")) {
            // Skip Spring/library handler methods that aren't part of our app surface
            return null;
        }
        String controller = handler.getBeanType().getSimpleName();
        String javaMethod = handler.getMethod().getName();
        String name = synthName(verb, path);

        List<Map<String, String>> params = extractParams(handler);
        String description = synthDescription(verb, path, javaMethod);
        String safety = classifySafety(verb, path, name, writeToolNames);
        List<String> tags = classifyTags(verb, path, safety);

        return AutoToolDescriptor.builder()
                .name(name)
                .httpMethod(verb)
                .path(path)
                .controller(controller)
                .javaMethod(javaMethod)
                .description(description)
                .parameters(params)
                .safetyLevel(safety)
                .tags(tags)
                .build();
    }

    private static String synthName(String verb, String path) {
        // get_api_admin_dealers_code  (path vars retained for traceability)
        String slug = path.replaceAll("[/{}]", "_").replaceAll("__+", "_").replaceAll("^_|_$", "");
        return verb.toLowerCase() + "_" + slug;
    }

    private static String synthDescription(String verb, String path, String javaMethod) {
        String action = switch (verb) {
            case "GET" -> "Read";
            case "POST" -> "Create or invoke";
            case "PUT" -> "Update";
            case "PATCH" -> "Partially update";
            case "DELETE" -> "Delete";
            default -> verb;
        };
        // Heuristic: split the java method name at camelCase, prepend the verb action.
        String humanized = javaMethod.replaceAll("([a-z])([A-Z])", "$1 $2").toLowerCase();
        return action + " — " + humanized + " (" + path + ")";
    }

    private List<Map<String, String>> extractParams(HandlerMethod handler) {
        List<Map<String, String>> out = new ArrayList<>();
        for (Parameter p : handler.getMethod().getParameters()) {
            Map<String, String> param = new LinkedHashMap<>();
            param.put("name", p.getName());
            param.put("type", p.getType().getSimpleName());
            if (p.isAnnotationPresent(PathVariable.class)) {
                param.put("kind", "path");
                PathVariable pv = p.getAnnotation(PathVariable.class);
                if (pv != null && !pv.value().isEmpty()) param.put("name", pv.value());
            } else if (p.isAnnotationPresent(RequestParam.class)) {
                param.put("kind", "query");
                RequestParam rp = p.getAnnotation(RequestParam.class);
                if (rp != null && !rp.value().isEmpty()) param.put("name", rp.value());
                if (rp != null) param.put("required", String.valueOf(rp.required()));
            } else if (p.isAnnotationPresent(org.springframework.web.bind.annotation.RequestBody.class)) {
                param.put("kind", "body");
            } else {
                continue; // skip Spring-injected (HttpServletRequest etc.)
            }
            out.add(param);
        }
        return out;
    }

    /**
     * Path-prefix-based safety classification. Conservative defaults — we
     * lean toward MORE restriction; admins can relax later.
     */
    private static String classifySafety(String verb, String path, String name, Set<String> writeToolNames) {
        // Hard NO surfaces — never expose to the agent
        if (path.startsWith("/api/auth/")) return "AGENT_NO";
        if (path.startsWith("/api/agent/") || path.startsWith("/api/admin/agent-")) return "AGENT_NO";
        if (path.startsWith("/actuator/")) return "AGENT_NO";
        if (path.startsWith("/mcp") || path.startsWith("/.well-known/")) return "AGENT_NO";

        // User management — admin only, dangerous credential ops
        if (path.startsWith("/api/admin/users")) return "ADMIN_ONLY";
        // System config — admin-only writes, restrict reads to admin too
        if (path.startsWith("/api/admin/config")) return "ADMIN_ONLY";

        boolean isWrite = !"GET".equals(verb);

        // Writes that have ActionHandler beans go through propose/confirm
        if (isWrite && writeToolNames.stream().anyMatch(name::contains)) {
            return "WRITE_VIA_PROPOSE";
        }
        // Other writes — flag broadly; agent can't invoke directly.
        if (isWrite) {
            return "WRITE";
        }

        // All reads land here — admin reads are usually fine for agent governance use
        if (path.startsWith("/api/admin/")) return "INTERNAL_READ";
        return "PUBLIC_READ";
    }

    private static List<String> classifyTags(String verb, String path, String safety) {
        List<String> tags = new ArrayList<>();
        tags.add(verb.toLowerCase());
        if (path.startsWith("/api/admin/")) tags.add("admin");
        if ("AGENT_NO".equals(safety)) tags.add("blocked-from-agent");
        if ("WRITE_VIA_PROPOSE".equals(safety)) tags.add("propose-confirm");
        // Domain tags
        if (path.contains("/customers")) tags.add("customer");
        if (path.contains("/deals")) tags.add("deal");
        if (path.contains("/vehicles") || path.contains("/stock") || path.contains("/floorplan")) tags.add("inventory");
        if (path.contains("/finance")) tags.add("finance");
        if (path.contains("/leads")) tags.add("crm");
        if (path.contains("/warranty") || path.contains("/recall") || path.contains("/registration")) tags.add("aftermarket");
        if (path.contains("/batch")) tags.add("batch");
        if (path.contains("/nhtsa")) tags.add("federal");
        return Collections.unmodifiableList(tags);
    }

    /** Map controller class names to friendly module labels. */
    private static String deriveModule(String controller) {
        if (controller == null) return "Other";
        String c = controller.replace("Controller", "");
        if (c.contains("Customer") || c.contains("Lead") || c.contains("CreditCheck")) return "Customers & Leads";
        if (c.contains("Deal")) return "Sales (Deals)";
        if (c.contains("Vehicle") || c.contains("Stock") || c.contains("FloorPlan") || c.contains("Production") || c.contains("Shipment") || c.contains("Pdi")) return "Inventory";
        if (c.contains("Finance") || c.contains("Loan") || c.contains("Lease")) return "Finance";
        if (c.contains("Registration") || c.contains("Warranty") || c.contains("Recall")) return "Aftermarket";
        if (c.contains("Batch") || c.contains("Report")) return "Batch & Reports";
        if (c.contains("Dealer") || c.contains("Salesperson") || c.contains("ModelMaster") || c.contains("PriceMaster") || c.contains("TaxRate") || c.contains("Incentive") || c.contains("LotLocation") || c.contains("Config")) return "Admin Master Data";
        if (c.contains("UserAdmin") || c.contains("Auth")) return "Auth & Users";
        if (c.contains("Audit") || c.contains("AgentTrace") || c.contains("AgentAnalytics") || c.contains("AgentUsage") || c.contains("CapabilityGap")) return "Observability";
        if (c.contains("Agent") || c.contains("Action") || c.contains("Composite") || c.contains("Chat") || c.contains("Mcp") || c.contains("AgentCard")) return "AI Surface";
        if (c.contains("Nhtsa")) return "External Data";
        if (c.contains("Vin")) return "VIN";
        return "Other";
    }
}
