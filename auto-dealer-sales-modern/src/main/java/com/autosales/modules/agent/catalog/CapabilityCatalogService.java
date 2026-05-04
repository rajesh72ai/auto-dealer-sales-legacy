package com.autosales.modules.agent.catalog;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.chat.ToolRegistry;
import com.autosales.modules.discovery.ToolDescriptorExtractor;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStream;
import java.util.*;

/**
 * Loads {@code agent-capabilities.yml} at startup, joins it with the live
 * {@link ToolRegistry} + {@link ActionRegistry}, and serves persona-ordered
 * capability lists to the Discovery UX surfaces (chips, slash menu, atlas).
 *
 * <p>Drift discipline (boot-time invariant):
 * <ul>
 *   <li>Every yaml {@code backedBy} entry MUST resolve to a real tool name or
 *       ActionHandler tool name. Missing → WARN (or FAIL if {@code agent.catalog.strict}).</li>
 *   <li>Every registered tool/action MUST be referenced by some capability,
 *       UNLESS listed in yaml's {@code internalTools}. Missing → WARN (or FAIL).</li>
 * </ul>
 *
 * <p>Reason for the check: pre-fix, the {@code log_capability_gap} tool was
 * referenced from the system prompt without a {@link ToolRegistry} entry —
 * Gemini emitted empty function calls and rows persisted with controller
 * defaults (project_agent_lessons_learned.md, Lesson 2). The same drift
 * shape would silently break the Discovery UX: a chip references a tool
 * the registry no longer has, the user clicks, the agent finds nothing.
 * Catch it at boot, not in a customer demo.
 */
@Service
public class CapabilityCatalogService {

    private static final Logger log = LoggerFactory.getLogger(CapabilityCatalogService.class);

    private static final String YAML_RESOURCE = "agent-capabilities.yml";

    private final ToolRegistry toolRegistry;
    private final ActionRegistry actionRegistry;
    private final ToolDescriptorExtractor descriptorExtractor;
    private final boolean strict;

    private List<AgentCapability> capabilities = List.of();
    private Set<String> internalTools = Set.of();
    private AutoDiscoveredTile autoDiscoveredTile;

    public CapabilityCatalogService(ToolRegistry toolRegistry,
                                    ActionRegistry actionRegistry,
                                    ToolDescriptorExtractor descriptorExtractor,
                                    @Value("${agent.catalog.strict:false}") boolean strict) {
        this.toolRegistry = toolRegistry;
        this.actionRegistry = actionRegistry;
        this.descriptorExtractor = descriptorExtractor;
        this.strict = strict;
    }

    @PostConstruct
    @SuppressWarnings("unchecked")
    void load() {
        Map<String, Object> root;
        try (InputStream in = new ClassPathResource(YAML_RESOURCE).getInputStream()) {
            root = new Yaml().load(in);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to load " + YAML_RESOURCE + ": " + e.getMessage(), e);
        }
        if (root == null) {
            throw new IllegalStateException(YAML_RESOURCE + " is empty");
        }

        List<String> internal = (List<String>) root.getOrDefault("internalTools", List.of());
        this.internalTools = new LinkedHashSet<>(internal);

        Map<String, Object> tile = (Map<String, Object>) root.get("autoDiscoveredTile");
        if (tile != null) {
            this.autoDiscoveredTile = new AutoDiscoveredTile(
                    str(tile, "id"),
                    str(tile, "displayName"),
                    str(tile, "description"),
                    list(tile, "examplePrompts"));
        }

        List<Map<String, Object>> raw = (List<Map<String, Object>>) root.getOrDefault("capabilities", List.of());
        List<AgentCapability> parsed = new ArrayList<>(raw.size());
        for (Map<String, Object> entry : raw) {
            int demoPriority = entry.get("demoPriority") instanceof Number n ? n.intValue() : 9999;
            boolean requiresProposal = Boolean.TRUE.equals(entry.get("requiresProposal"));
            parsed.add(new AgentCapability(
                    str(entry, "id"),
                    str(entry, "displayName"),
                    str(entry, "description"),
                    str(entry, "category"),
                    list(entry, "examplePrompts"),
                    list(entry, "backedBy"),
                    list(entry, "personas"),
                    demoPriority,
                    requiresProposal,
                    demoPriority /* base; persona-adjusted at request time */
            ));
        }
        this.capabilities = List.copyOf(parsed);

        runDriftCheck();
    }

    /**
     * Validate that yaml ↔ registry references agree. Drift here is the same
     * failure shape that bit us in capability-gap-empty-rows: a contract
     * referenced from one side but absent from the other, surfacing as
     * silent degradation in production.
     */
    private void runDriftCheck() {
        // Tool names actually registered for the agent
        Set<String> registeredReadTools = extractRegisteredReadToolNames();
        Set<String> registeredWriteActions = new LinkedHashSet<>(actionRegistry.names());

        Set<String> registered = new LinkedHashSet<>();
        registered.addAll(registeredReadTools);
        registered.addAll(registeredWriteActions);

        // Names referenced from yaml `backedBy`
        Set<String> referenced = new LinkedHashSet<>();
        for (AgentCapability c : capabilities) {
            referenced.addAll(c.backedBy());
        }

        // (1) yaml refs that don't resolve to a real tool/action
        Set<String> orphanRefs = new LinkedHashSet<>(referenced);
        orphanRefs.removeAll(registered);
        if (!orphanRefs.isEmpty()) {
            String msg = "agent-capabilities.yml references unknown tools/actions: " + orphanRefs;
            if (strict) throw new IllegalStateException(msg);
            log.warn(msg);
        }

        // (2) registered tools/actions that no capability references AND aren't internal
        Set<String> unmapped = new LinkedHashSet<>(registered);
        unmapped.removeAll(referenced);
        unmapped.removeAll(internalTools);
        if (!unmapped.isEmpty()) {
            String msg = "Registered tools/actions are not surfaced in any capability "
                    + "(add a yaml entry or list under internalTools): " + unmapped;
            if (strict) throw new IllegalStateException(msg);
            log.warn(msg);
        }

        log.info("CapabilityCatalogService loaded: capabilities={}, internalTools={}, "
                        + "registeredReadTools={}, registeredWriteActions={}",
                capabilities.size(), internalTools.size(),
                registeredReadTools.size(), registeredWriteActions.size());
    }

    /**
     * Persona-aware view of the catalog. Capabilities whose {@code personas}
     * list contains the caller's role get a priority boost (sort earlier);
     * everything else falls back to {@code demoPriority}. When {@code role}
     * is null, returns the catalog in raw demoPriority order.
     */
    public List<AgentCapability> forRole(UserRole role) {
        List<AgentCapability> adjusted = new ArrayList<>(capabilities.size());
        for (AgentCapability c : capabilities) {
            int adjusted_priority = c.demoPriority();
            if (role != null && c.personas() != null && c.personas().contains(role.name())) {
                // Persona match — boost (subtract a constant so persona-relevant
                // capabilities sort ahead of non-relevant ones at the same
                // demoPriority tier, while preserving the demoPriority tie-break)
                adjusted_priority -= 1000;
            }
            adjusted.add(new AgentCapability(
                    c.id(), c.displayName(), c.description(), c.category(),
                    c.examplePrompts(), c.backedBy(), c.personas(),
                    c.demoPriority(), c.requiresProposal(), adjusted_priority));
        }
        adjusted.sort(Comparator.comparingInt(AgentCapability::displayPriority));
        return adjusted;
    }

    public AutoDiscoveredTile autoDiscoveredTile() {
        if (autoDiscoveredTile == null) return null;
        // Substitute {{count}} with the live extractor count so the tile copy
        // stays honest as endpoints come and go.
        int count = descriptorExtractor.getCatalog().size();
        String description = autoDiscoveredTile.description() == null
                ? null
                : autoDiscoveredTile.description().replace("{{count}}", String.valueOf(count));
        return new AutoDiscoveredTile(
                autoDiscoveredTile.id(),
                autoDiscoveredTile.displayName(),
                description,
                autoDiscoveredTile.examplePrompts());
    }

    /**
     * Extract tool names from {@link ToolRegistry#getToolDefinitions()} —
     * each entry is a {@code {type, function: {name, description, parameters}}}
     * map. We only need the names for drift detection.
     */
    @SuppressWarnings("unchecked")
    private Set<String> extractRegisteredReadToolNames() {
        Set<String> names = new LinkedHashSet<>();
        for (Map<String, Object> def : toolRegistry.getToolDefinitions()) {
            Object fn = def.get("function");
            if (fn instanceof Map<?, ?> m) {
                Object name = m.get("name");
                if (name instanceof String s && !s.isBlank()) names.add(s);
            }
        }
        return names;
    }

    private static String str(Map<String, Object> map, String key) {
        Object v = map.get(key);
        return v == null ? null : v.toString();
    }

    @SuppressWarnings("unchecked")
    private static List<String> list(Map<String, Object> map, String key) {
        Object v = map.get(key);
        if (v == null) return List.of();
        if (v instanceof List<?> l) {
            List<String> out = new ArrayList<>(l.size());
            for (Object o : l) out.add(o == null ? null : o.toString());
            return List.copyOf(out);
        }
        return List.of();
    }

    /**
     * Single tile representing the auto-discovered admin endpoint surface.
     * Doesn't appear in {@link #capabilities} because it isn't backed by a
     * specific tool — it represents the keyword-retrieval fallback path.
     */
    public record AutoDiscoveredTile(
            String id,
            String displayName,
            String description,
            List<String> examplePrompts
    ) {}
}
