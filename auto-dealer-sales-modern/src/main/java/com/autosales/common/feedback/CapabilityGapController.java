package com.autosales.common.feedback;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * REST controller for the capability gap backlog.
 *
 * <ul>
 *   <li>{@code POST /api/capability-gaps} — any authenticated user (called by AI tool)</li>
 *   <li>{@code GET /api/capability-gaps} — ADMIN only (backlog listing)</li>
 *   <li>{@code GET /api/capability-gaps/dashboard} — ADMIN only (summary dashboard)</li>
 *   <li>{@code PATCH /api/capability-gaps/{id}/status} — ADMIN only (triage)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/capability-gaps")
@RequiredArgsConstructor
public class CapabilityGapController {

    private final CapabilityGapService service;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> logGap(@RequestBody Map<String, Object> body) {
        CapabilityGapLog entry = CapabilityGapLog.builder()
                .appId(str(body, "appId", "AUTOSALES"))
                .appName(str(body, "appName", "Auto Dealer Sales"))
                .sourceSystem(str(body, "sourceSystem", "AGENT"))
                .userId(str(body, "userId", null))
                .dealerCode(str(body, "dealerCode", null))
                .requestedCapability(str(body, "requestedCapability", "unknown"))
                .category(str(body, "category", "UNKNOWN"))
                .userInput(str(body, "userInput", ""))
                .scenarioDescription(str(body, "scenarioDescription", ""))
                .agentReasoning(str(body, "agentReasoning", ""))
                .suggestedAlternative(str(body, "suggestedAlternative", null))
                .priorityHint(str(body, "priorityHint", "MEDIUM"))
                .build();
        CapabilityGapLog saved = service.record(entry);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("gapId", saved.getGapId(), "status", "logged"));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<CapabilityGapLog>> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<CapabilityGapLog> result = (status != null)
                ? service.listByStatus(status, page, size)
                : service.listAll(page, size);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> dashboard() {
        return ResponseEntity.ok(service.getDashboard());
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<CapabilityGapLog> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String newStatus = body.getOrDefault("status", "REVIEWED");
        String notes = body.get("resolutionNotes");
        return ResponseEntity.ok(service.updateStatus(id, newStatus, notes));
    }

    private String str(Map<String, Object> map, String key, String defaultVal) {
        Object v = map.get(key);
        return (v != null) ? v.toString() : defaultVal;
    }
}
