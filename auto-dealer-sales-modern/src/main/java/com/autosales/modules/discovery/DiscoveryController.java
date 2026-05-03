package com.autosales.modules.discovery;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Read-only endpoints over the auto-extracted endpoint catalog
 * ({@link ToolDescriptorExtractor}). Drives both:
 * <ul>
 *   <li>{@code /admin/api-docs} — support engineer documentation page</li>
 *   <li>{@code /admin/agent-discovery} — agent governance view (safety levels, AGENT_NO flags)</li>
 * </ul>
 *
 * <p>The agent's runtime keyword retrieval also reads from this catalog
 * via {@link ToolDescriptorExtractor#getCatalog()} directly (in-process,
 * not over HTTP).
 */
@RestController
@RequestMapping("/api/admin/discovery")
@RequiredArgsConstructor
public class DiscoveryController {

    private final ToolDescriptorExtractor extractor;

    /** Full catalog with optional filters. Used by the support docs page. */
    @GetMapping("/catalog")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
    public ResponseEntity<Map<String, Object>> catalog(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String safetyLevel,
            @RequestParam(required = false) String httpMethod,
            @RequestParam(required = false) String tag) {
        List<AutoToolDescriptor> filtered = extractor.getCatalog().stream()
                .filter(d -> matchesSearch(d, search))
                .filter(d -> safetyLevel == null || safetyLevel.equalsIgnoreCase(d.getSafetyLevel()))
                .filter(d -> httpMethod == null || httpMethod.equalsIgnoreCase(d.getHttpMethod()))
                .filter(d -> tag == null || (d.getTags() != null && d.getTags().contains(tag.toLowerCase(Locale.ROOT))))
                .toList();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("total", filtered.size());
        body.put("totalUnfiltered", extractor.getCatalog().size());
        body.put("countsByLevel", extractor.getCountsByLevel());
        body.put("descriptors", filtered);
        return ResponseEntity.ok(body);
    }

    /** Catalog grouped by inferred module — friendly default for the docs page. */
    @GetMapping("/by-module")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
    public ResponseEntity<Map<String, Object>> byModule() {
        Map<String, List<AutoToolDescriptor>> grouped = extractor.getByModule();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("modules", grouped);
        body.put("countsByLevel", extractor.getCountsByLevel());
        body.put("totalEndpoints", extractor.getCatalog().size());
        return ResponseEntity.ok(body);
    }

    /** Quick stats — useful for the agent-governance dashboard tile. */
    @GetMapping("/stats")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ResponseEntity<Map<String, Object>> stats() {
        List<AutoToolDescriptor> all = extractor.getCatalog();
        long modules = extractor.getByModule().size();
        long readPublic = all.stream().filter(d -> "PUBLIC_READ".equals(d.getSafetyLevel())).count();
        long readInternal = all.stream().filter(d -> "INTERNAL_READ".equals(d.getSafetyLevel())).count();
        long writeProp = all.stream().filter(d -> "WRITE_VIA_PROPOSE".equals(d.getSafetyLevel())).count();
        long writeOther = all.stream().filter(d -> "WRITE".equals(d.getSafetyLevel())).count();
        long adminOnly = all.stream().filter(d -> "ADMIN_ONLY".equals(d.getSafetyLevel())).count();
        long agentNo = all.stream().filter(d -> "AGENT_NO".equals(d.getSafetyLevel())).count();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("totalEndpoints", all.size());
        body.put("modules", modules);
        body.put("publicReads", readPublic);
        body.put("internalReads", readInternal);
        body.put("writesViaPropose", writeProp);
        body.put("otherWrites", writeOther);
        body.put("adminOnly", adminOnly);
        body.put("agentNo", agentNo);
        body.put("agentDiscoverable", readPublic + readInternal + writeProp);
        return ResponseEntity.ok(body);
    }

    private static boolean matchesSearch(AutoToolDescriptor d, String search) {
        if (search == null || search.isBlank()) return true;
        String s = search.toLowerCase(Locale.ROOT);
        return (d.getName() != null && d.getName().toLowerCase(Locale.ROOT).contains(s))
                || (d.getPath() != null && d.getPath().toLowerCase(Locale.ROOT).contains(s))
                || (d.getDescription() != null && d.getDescription().toLowerCase(Locale.ROOT).contains(s))
                || (d.getController() != null && d.getController().toLowerCase(Locale.ROOT).contains(s));
    }
}
