package com.autosales.modules.agent.usage;

import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.Map;

/**
 * Two endpoints split by audience:
 *
 * <ul>
 *   <li>{@code GET /api/agent/usage/quota/me} — every signed-in user; reports
 *       only their own quota. Accurate, local-only.</li>
 *   <li>{@code GET /api/agent/usage/actuals} — ADMIN only; reports real $ and
 *       token breakdown from the Anthropic admin API across the whole org.</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/agent/usage")
@RequiredArgsConstructor
public class AgentUsageController {

    private final AgentUsageService usageService;

    @GetMapping("/quota/me")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
    public ResponseEntity<Map<String, Object>> quotaForMe() {
        return ResponseEntity.ok(usageService.quotaFor(currentUserId()));
    }

    @GetMapping("/actuals")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> actuals(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(usageService.adminSummary(from, to));
    }

    private String currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.getName() != null) ? auth.getName() : "anonymous";
    }
}
