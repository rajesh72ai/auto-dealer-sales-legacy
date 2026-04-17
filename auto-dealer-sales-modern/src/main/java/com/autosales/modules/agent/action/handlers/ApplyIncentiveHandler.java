package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.sales.dto.ApplyIncentivesRequest;
import com.autosales.modules.sales.dto.DealResponse;
import com.autosales.modules.sales.service.DealService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class ApplyIncentiveHandler implements ActionHandler {

    private final DealService dealService;
    private final PayloadValidator payloadValidator;

    @Override public String toolName() { return "apply_incentive"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.SALESPERSON, UserRole.MANAGER, UserRole.ADMIN, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/deals/{dealNumber}/incentives"; }
    @Override public boolean reversible() { return true; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String dealNumber = requireDealNumber(payload);
        ApplyIncentivesRequest req = toRequest(payload);
        DealResponse tentative = dealService.applyIncentives(dealNumber, req);
        ImpactPreview preview = buildPreview(dealNumber, tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String dealNumber = requireDealNumber(payload);
        ApplyIncentivesRequest req = toRequest(payload);
        return dealService.applyIncentives(dealNumber, req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof DealResponse)) return null;
        ApplyIncentivesRequest req = toRequest(payload);
        return Map.of(
            "action", "remove_incentive",
            "dealNumber", requireDealNumber(payload),
            "incentiveIds", req.getIncentiveIds()
        );
    }

    private String requireDealNumber(Map<String, Object> payload) {
        Object raw = payload.get("dealNumber");
        if (raw == null || raw.toString().isBlank()) {
            throw new IllegalArgumentException("dealNumber is required in payload for apply_incentive");
        }
        return raw.toString();
    }

    private ApplyIncentivesRequest toRequest(Map<String, Object> payload) {
        Map<String, Object> filtered = new java.util.HashMap<>(payload);
        filtered.remove("dealNumber");
        return payloadValidator.convertAndValidate(filtered, ApplyIncentivesRequest.class);
    }

    private ImpactPreview buildPreview(String dealNumber, DealResponse deal, ApplyIncentivesRequest req) {
        BigDecimal rebates = deal.getRebatesApplied() == null ? BigDecimal.ZERO : deal.getRebatesApplied();
        BigDecimal total = deal.getTotalPrice() == null ? BigDecimal.ZERO : deal.getTotalPrice();

        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Apply %d incentive(s) to deal %s",
                        req.getIncentiveIds().size(), dealNumber))
                .reversible(true)
                .build();
        for (String id : req.getIncentiveIds()) {
            p.addChange("+ IncentiveApplied: " + id);
        }
        p.addChange("Updated rebatesApplied: " + money(rebates));
        p.addChange("Updated total price: " + money(total));
        p.setDetail(Map.of(
            "dealNumber", dealNumber,
            "incentiveIds", req.getIncentiveIds()
        ));
        return p;
    }

    private static String money(BigDecimal b) {
        if (b == null) return "$0.00";
        return String.format("$%,.2f", b);
    }
}
