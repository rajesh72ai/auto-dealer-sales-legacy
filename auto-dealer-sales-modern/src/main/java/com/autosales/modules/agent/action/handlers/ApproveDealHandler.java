package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.sales.dto.ApprovalRequest;
import com.autosales.modules.sales.dto.ApprovalResponse;
import com.autosales.modules.sales.service.DealService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class ApproveDealHandler implements ActionHandler {

    private final DealService dealService;
    private final ObjectMapper mapper;

    @Override public String toolName() { return "approve_deal"; }
    @Override public Tier tier()       { return Tier.B; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.MANAGER, UserRole.ADMIN);
    }
    @Override public String endpointDescriptor() { return "POST /api/deals/{dealNumber}/approve"; }
    @Override public boolean reversible() { return false; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String dealNumber = requireDealNumber(payload);
        ApprovalRequest req = toRequest(payload, user);
        ApprovalResponse tentative = dealService.approve(dealNumber, req);
        ImpactPreview preview = buildPreview(dealNumber, tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String dealNumber = requireDealNumber(payload);
        ApprovalRequest req = toRequest(payload, user);
        return dealService.approve(dealNumber, req);
    }

    private String requireDealNumber(Map<String, Object> payload) {
        Object raw = payload.get("dealNumber");
        if (raw == null || raw.toString().isBlank()) {
            throw new IllegalArgumentException("dealNumber is required in payload for approve_deal");
        }
        return raw.toString();
    }

    private ApprovalRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new java.util.HashMap<>(payload);
        filtered.remove("dealNumber");
        ApprovalRequest req = mapper.convertValue(filtered, ApprovalRequest.class);
        if (req.getApproverId() == null || req.getApproverId().isBlank()) {
            req.setApproverId(user.getUserId());
        }
        if (req.getApprovalType() == null || req.getApprovalType().isBlank()) {
            req.setApprovalType(user.getRole() == UserRole.ADMIN ? "GM" : "MG");
        }
        return req;
    }

    private ImpactPreview buildPreview(String dealNumber, ApprovalResponse resp, ApprovalRequest req) {
        String verb = "AP".equals(req.getAction()) ? "Approve" : "Reject";
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("%s deal %s (%s → %s)",
                        verb, dealNumber,
                        resp.getOldStatusDescription(), resp.getNewStatusDescription()))
                .reversible(false)
                .build();
        p.addChange(String.format("+ SalesApproval (%s by %s)",
                req.getApprovalType(), resp.getApproverName() != null ? resp.getApproverName() : req.getApproverId()));
        p.addChange(String.format("Status: %s → %s", resp.getOldStatus(), resp.getNewStatus()));
        if (req.getComments() != null && !req.getComments().isBlank()) {
            p.addChange("Comments: " + req.getComments());
        }
        if (resp.getThresholdMessage() != null && !resp.getThresholdMessage().isBlank()) {
            p.addWarning(resp.getThresholdMessage());
        }
        p.setDetail(Map.of(
            "dealNumber", dealNumber,
            "action", req.getAction(),
            "approvalType", req.getApprovalType()
        ));
        return p;
    }
}
