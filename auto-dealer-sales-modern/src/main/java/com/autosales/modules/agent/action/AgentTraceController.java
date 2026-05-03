package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.autosales.modules.agent.action.repository.AgentToolCallAuditRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Admin trace UI backend — returns the full per-tool-call timeline for a
 * conversation. Closes hardening Gap F (tool-call visibility) on the GCP /
 * Gemini path: every {@code function_call} the agent emits is recorded by
 * {@link AgentToolCallAuditService#recordReadToolCall}, and every
 * propose/confirm/execute step is recorded by {@link ActionService}. This
 * endpoint surfaces the merged timeline.
 */
@RestController
@RequestMapping("/api/admin/agent-trace")
@RequiredArgsConstructor
public class AgentTraceController {

    private final AgentToolCallAuditRepository repo;

    /** List recent conversations with audit activity — admin landing page data. */
    @GetMapping("/recent")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ResponseEntity<List<Map<String, Object>>> recent(@RequestParam(defaultValue = "30") int limit) {
        var rows = repo.findRecentConversations(Math.min(limit, 200));
        List<Map<String, Object>> out = rows.stream().map(r -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("conversationId", r.getConversationId());
            m.put("lastActivityTs", r.getLastActivityTs());
            m.put("rowCount", r.getRowCount());
            m.put("userId", r.getUserId());
            m.put("dealerCode", r.getDealerCode());
            return m;
        }).collect(Collectors.toList());
        return ResponseEntity.ok(out);
    }

    @GetMapping("/{conversationId}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ResponseEntity<Map<String, Object>> trace(@PathVariable String conversationId,
                                                     @RequestParam(defaultValue = "0") int page,
                                                     @RequestParam(defaultValue = "200") int size) {
        Pageable pageable = PageRequest.of(page, Math.min(size, 500));
        var pageResult = repo.findByConversationIdOrderByCreatedTsAsc(conversationId, pageable);
        List<Map<String, Object>> rows = pageResult.getContent().stream()
                .map(AgentTraceController::toRow)
                .collect(Collectors.toList());
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("conversationId", conversationId);
        body.put("totalRows", pageResult.getTotalElements());
        body.put("page", pageResult.getNumber());
        body.put("size", pageResult.getSize());
        body.put("rows", rows);
        return ResponseEntity.ok(body);
    }

    private static Map<String, Object> toRow(AgentToolCallAudit a) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("auditId", a.getAuditId());
        r.put("createdTs", a.getCreatedTs());
        r.put("userId", a.getUserId());
        r.put("userRole", a.getUserRole());
        r.put("dealerCode", a.getDealerCode());
        r.put("toolName", a.getToolName());
        r.put("tier", a.getTier());
        r.put("status", a.getStatus());
        r.put("dryRun", a.getDryRun());
        r.put("reversible", a.getReversible());
        r.put("undone", a.getUndone());
        r.put("elapsedMs", a.getElapsedMs());
        r.put("httpStatus", a.getHttpStatus());
        r.put("endpoint", a.getEndpoint());
        r.put("proposalToken", a.getProposalToken());
        r.put("payloadJson", a.getPayloadJson());
        r.put("previewJson", a.getPreviewJson());
        r.put("responseJson", a.getResponseJson());
        r.put("errorMessage", a.getErrorMessage());
        return r;
    }
}
