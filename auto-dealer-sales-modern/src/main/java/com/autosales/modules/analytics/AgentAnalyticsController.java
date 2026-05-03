package com.autosales.modules.analytics;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Admin analytics endpoints sourced from BigQuery (B3a + B3b).
 *
 * <ul>
 *   <li>{@code /api/admin/agent-analytics/tool-calls} — per-tool aggregates
 *       (count, p50/p95 latency, failure rate) over a date range. Sourced
 *       from {@code autosales_analytics.tool_call_audit} (mirrored async
 *       from Cloud SQL).</li>
 *   <li>{@code /api/admin/agent-analytics/daily} — per-day rollup of agent
 *       activity (tool calls, conversations, users, reads, writes,
 *       failures).</li>
 *   <li>{@code /api/admin/agent-analytics/cost} — per-day Gemini spend from
 *       the Cloud Billing → BigQuery export. Returns informational stub if
 *       the billing-export table id isn't configured yet.</li>
 * </ul>
 *
 * Activated alongside {@link BigQueryAnalyticsService} via the
 * {@code analytics.bigquery.enabled} flag.
 */
@RestController
@RequestMapping("/api/admin/agent-analytics")
@RequiredArgsConstructor
@ConditionalOnProperty(name = "analytics.bigquery.enabled", havingValue = "true")
public class AgentAnalyticsController {

    private final BigQueryAnalyticsService analytics;

    @GetMapping("/tool-calls")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ResponseEntity<Map<String, Object>> toolCalls(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("from", from.toString());
        body.put("to", to.toString());
        body.put("rows", analytics.toolCallAnalytics(from, to));
        return ResponseEntity.ok(body);
    }

    @GetMapping("/daily")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ResponseEntity<Map<String, Object>> daily(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("from", from.toString());
        body.put("to", to.toString());
        body.put("rows", analytics.dailyActivity(from, to));
        return ResponseEntity.ok(body);
    }

    @GetMapping("/cost")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> cost(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("from", from.toString());
        body.put("to", to.toString());
        body.put("rows", analytics.geminiCostByDay(from, to));
        return ResponseEntity.ok(body);
    }

    /** Reports configured/enabled state — useful for the frontend to show wiring banners. */
    @GetMapping("/status")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ResponseEntity<List<Map<String, String>>> status() {
        // Simple presence indicator — useful for the page header
        Map<String, String> info = new LinkedHashMap<>();
        info.put("status", "ENABLED");
        info.put("source", "BigQuery");
        info.put("note", "Audit rows mirror to autosales_analytics.tool_call_audit; billing export read from configured table.");
        return ResponseEntity.ok(List.of(info));
    }
}
