package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.dto.ExecutionResult;
import com.autosales.modules.agent.action.dto.ProposalResponse;
import com.autosales.modules.agent.action.dto.ProposeRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/agent/actions")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
@RequiredArgsConstructor
public class ActionController {

    private final ActionService actionService;
    private final ActionRegistry registry;
    private final UndoService undoService;
    private final CurrentUserContext userContext;

    @PostMapping("/propose")
    public ResponseEntity<ProposalResponse> propose(@Valid @RequestBody ProposeRequest req) {
        ProposalResponse resp = actionService.propose(req.getToolName(), req.getPayload(), req.getConversationId());
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/confirm/{token}")
    public ResponseEntity<ExecutionResult> confirm(@PathVariable String token) {
        return ResponseEntity.ok(actionService.confirm(token));
    }

    @DeleteMapping("/reject/{token}")
    public ResponseEntity<ExecutionResult> reject(@PathVariable String token) {
        return ResponseEntity.ok(actionService.reject(token));
    }

    /**
     * Undo a previously-EXECUTED reversible action within its undo window.
     * Returns 200 with the compensation result on success; 400/410 if the
     * window has expired, the action was not reversible, was already undone,
     * or the compensation action is not yet activated for this tool.
     */
    @PostMapping("/undo/{auditId}")
    public ResponseEntity<ExecutionResult> undo(@PathVariable Long auditId) {
        return ResponseEntity.ok(undoService.execute(auditId, userContext.current()));
    }

    @GetMapping("/registry")
    public ResponseEntity<List<Map<String, Object>>> registryList() {
        List<Map<String, Object>> entries = registry.all().stream()
                .map(h -> Map.<String, Object>of(
                        "toolName", h.toolName(),
                        "tier", h.tier().getCode(),
                        "endpoint", h.endpointDescriptor(),
                        "reversible", h.reversible(),
                        "allowedRoles", h.allowedRoles().stream().map(Enum::name).toList()
                ))
                .toList();
        return ResponseEntity.ok(entries);
    }
}
