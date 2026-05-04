package com.autosales.modules.discovery;

import com.autosales.modules.agent.action.ActionRegistry;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.security.access.prepost.PreAuthorize;
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

        // Build a Set of "VERB /path" descriptors from each ActionHandler's
        // endpointDescriptor() — these are the exact paths protected by
        // propose/confirm. Anything matching gets WRITE_VIA_PROPOSE classification
        // instead of WRITE. We compare normalized (collapse multiple slashes,
        // strip trailing /) so handler-declared "POST /api/leads" matches a
        // route registered as "/api/leads".
        Set<String> proposeProtectedDescriptors = new java.util.HashSet<>();
        actionRegistry.all().forEach(h -> {
            String d = h.endpointDescriptor();
            if (d != null && !d.isBlank()) {
                proposeProtectedDescriptors.add(normalizeDescriptor(d));
            }
        });
        log.info("ToolDescriptorExtractor: {} ActionHandler-protected endpoints will be classified WRITE_VIA_PROPOSE: {}",
                proposeProtectedDescriptors.size(), proposeProtectedDescriptors);

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
                        AutoToolDescriptor d = build(handler, path, method.name(), proposeProtectedDescriptors);
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

    private AutoToolDescriptor build(HandlerMethod handler, String path, String verb, Set<String> proposeProtectedDescriptors) {
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
        String safety = classifySafety(verb, path, proposeProtectedDescriptors);

        // Lesson 4 reinforcement: a path-prefix-based classification cannot
        // see Spring @PreAuthorize role gates. If the endpoint's effective
        // role list omits AGENT_SERVICE, the agent's X-API-Key route will
        // 403 at runtime — discovering it is worse than not discovering it.
        // Downgrade reads to AGENT_NO so retrieval skips them entirely.
        // (Writes are already filtered out of retrieval; classification stays
        // for documentation accuracy.)
        if (("PUBLIC_READ".equals(safety) || "INTERNAL_READ".equals(safety))
                && !isAgentReachable(handler)) {
            safety = "AGENT_NO";
        }

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
     * Decide whether the agent's service-account auth surface (X-API-Key
     * granting only ROLE_AGENT_SERVICE) can actually reach this handler.
     *
     * <p>Spring resolution: a method-level {@code @PreAuthorize} overrides
     * the class-level annotation. We check method first, fall back to
     * class. No annotation at all → permissive (any authenticated caller).
     *
     * <p>The role-list parsing here is a string match on the SpEL
     * expression — good enough for our hand-written controllers, all of
     * which use {@code hasAnyRole('A','B',...)}. If we ever start using
     * computed expressions (rare), this would need a real SpEL evaluator.
     */
    private static boolean isAgentReachable(HandlerMethod handler) {
        PreAuthorize ann = handler.getMethodAnnotation(PreAuthorize.class);
        if (ann == null) {
            ann = handler.getBeanType().getAnnotation(PreAuthorize.class);
        }
        if (ann == null) {
            // No annotation → endpoint allows any authenticated principal,
            // including ROLE_AGENT_SERVICE. Reachable.
            return true;
        }
        String expr = ann.value();
        return expr != null && expr.contains("AGENT_SERVICE");
    }

    /**
     * Path-prefix-based safety classification, with ActionHandler endpoint
     * paths upgraded to WRITE_VIA_PROPOSE. Conservative defaults — we lean
     * toward MORE restriction; admins can relax later.
     */
    private static String classifySafety(String verb, String path, Set<String> proposeProtectedDescriptors) {
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

        // Writes that match a registered ActionHandler's endpointDescriptor go
        // through propose/confirm — the agent can never invoke them directly.
        if (isWrite) {
            String descriptor = normalizeDescriptor(verb + " " + path);
            if (proposeProtectedDescriptors.contains(descriptor)) {
                return "WRITE_VIA_PROPOSE";
            }
            return "WRITE";
        }

        // All reads land here — admin reads are usually fine for agent governance use
        if (path.startsWith("/api/admin/")) return "INTERNAL_READ";
        return "PUBLIC_READ";
    }

    /**
     * Normalize a "VERB /path" descriptor for cross-comparison. ActionHandler
     * descriptors come from human-typed strings (e.g. "POST /api/leads") while
     * Spring registers paths with normalized slashes — collapse multiple
     * slashes, strip trailing slash, uppercase the verb.
     */
    private static String normalizeDescriptor(String d) {
        String s = d.trim().replaceAll("\\s+", " ");
        int sp = s.indexOf(' ');
        if (sp < 0) return s;
        String verb = s.substring(0, sp).toUpperCase();
        String path = s.substring(sp + 1).replaceAll("/+", "/");
        if (path.length() > 1 && path.endsWith("/")) path = path.substring(0, path.length() - 1);
        return verb + " " + path;
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
