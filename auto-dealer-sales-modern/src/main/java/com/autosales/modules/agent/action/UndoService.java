package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.dto.ExecutionResult;
import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.autosales.modules.agent.action.repository.AgentToolCallAuditRepository;
import com.autosales.modules.customer.service.CustomerLeadService;
import com.autosales.modules.sales.dto.CancellationRequest;
import com.autosales.modules.sales.service.DealService;
import com.autosales.modules.vehicle.service.StockTransferService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Executes the compensation recipe stored on a previously-EXECUTED reversible
 * Tier A/B audit row. Window is bounded by {@code undo_expires_at} which the
 * audit service set at execute time using {@code agent.action.undo-window-seconds}
 * (default 60s).
 *
 * <p>Compensation dispatch is action-name-based. v1 supports the most common
 * three; the rest gracefully refuse with "not yet activated" so the user sees
 * a clean message instead of a stack trace.
 *
 * <p>Supported in v1:
 * <ul>
 *   <li>{@code cancel_deal} — undo of {@code create_deal}</li>
 *   <li>{@code cancel_transfer} — undo of {@code transfer_stock}</li>
 *   <li>{@code close_lead} — undo of {@code create_lead}</li>
 * </ul>
 *
 * <p>Future: {@code remove_trade_in}, {@code withdraw_finance_app},
 * {@code remove_incentive} — those service methods don't exist yet.
 */
@Service
@RequiredArgsConstructor
public class UndoService {

    private static final Logger log = LoggerFactory.getLogger(UndoService.class);

    private final AgentToolCallAuditRepository auditRepo;
    private final ObjectMapper mapper;
    private final DealService dealService;
    private final StockTransferService transferService;
    private final CustomerLeadService leadService;

    public boolean activated() {
        return true;
    }

    @Transactional
    public ExecutionResult execute(Long auditId, CurrentUserContext.Snapshot user) {
        AgentToolCallAudit audit = auditRepo.findById(auditId)
                .orElseThrow(() -> new IllegalArgumentException("Audit row " + auditId + " not found"));

        // Identity check — only the original caller can undo their own action.
        if (!audit.getUserId().equals(user.getUserId())) {
            throw new SecurityException("Audit row " + auditId + " belongs to a different user");
        }

        // State checks — must be a real EXECUTED reversible row that hasn't been undone.
        if (!"EXECUTED".equals(audit.getStatus())) {
            throw new IllegalStateException("Cannot undo: audit row is " + audit.getStatus());
        }
        if (!Boolean.TRUE.equals(audit.getReversible())) {
            throw new IllegalStateException("Cannot undo: action was not reversible");
        }
        if (Boolean.TRUE.equals(audit.getUndone())) {
            throw new IllegalStateException("Action has already been undone");
        }
        if (audit.getUndoExpiresAt() == null
                || audit.getUndoExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Undo window has expired");
        }
        if (audit.getCompensationJson() == null || audit.getCompensationJson().isBlank()) {
            throw new IllegalStateException("No compensation recipe stored for this audit row");
        }

        Map<String, Object> compensation = parseCompensation(audit.getCompensationJson());
        String action = String.valueOf(compensation.get("action"));

        Object result = dispatch(action, compensation);

        audit.setUndone(true);
        audit.setUndoneAt(LocalDateTime.now());
        auditRepo.save(audit);

        log.info("UNDO executed: auditId={}, originalTool={}, compensationAction={}, user={}",
                auditId, audit.getToolName(), action, user.getUserId());

        return ExecutionResult.builder()
                .toolName("undo:" + audit.getToolName())
                .status("UNDONE")
                .result(result)
                .auditId(auditId)
                .message("Action undone via " + action)
                .reversible(false)
                .build();
    }

    private Object dispatch(String action, Map<String, Object> comp) {
        return switch (action) {
            case "cancel_deal" -> {
                String dealNumber = String.valueOf(comp.get("dealNumber"));
                String reason = comp.get("reason") != null
                        ? String.valueOf(comp.get("reason"))
                        : "Undone by agent within undo window";
                CancellationRequest req = new CancellationRequest();
                req.setReason(reason);
                yield dealService.cancelDeal(dealNumber, req);
            }
            case "cancel_transfer" -> {
                int transferId = ((Number) comp.get("transferId")).intValue();
                yield transferService.cancelTransfer(transferId);
            }
            case "close_lead" -> {
                Integer leadId = ((Number) comp.get("leadId")).intValue();
                String newStatus = comp.get("leadStatus") != null
                        ? String.valueOf(comp.get("leadStatus"))
                        : "DD";
                yield leadService.updateStatus(leadId, newStatus);
            }
            default -> throw new UnsupportedOperationException(
                    "Undo for compensation action '" + action + "' is not yet activated. "
                            + "Supported actions: cancel_deal, cancel_transfer, close_lead.");
        };
    }

    private Map<String, Object> parseCompensation(String json) {
        try {
            return mapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalStateException("Compensation JSON could not be parsed", e);
        }
    }
}
