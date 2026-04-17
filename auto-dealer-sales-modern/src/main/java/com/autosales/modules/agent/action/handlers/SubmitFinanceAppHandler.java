package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.finance.dto.FinanceAppRequest;
import com.autosales.modules.finance.dto.FinanceAppResponse;
import com.autosales.modules.finance.service.FinanceAppService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class SubmitFinanceAppHandler implements ActionHandler {

    private final FinanceAppService financeAppService;
    private final ObjectMapper mapper;

    @Override public String toolName() { return "submit_finance_app"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.FINANCE, UserRole.MANAGER, UserRole.ADMIN, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/finance/applications"; }
    @Override public boolean reversible() { return true; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        FinanceAppRequest req = toRequest(payload);
        FinanceAppResponse tentative = financeAppService.createApplication(req);
        ImpactPreview preview = buildPreview(tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        FinanceAppRequest req = toRequest(payload);
        return financeAppService.createApplication(req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof FinanceAppResponse resp)) return null;
        return Map.of(
            "action", "withdraw_finance_app",
            "financeId", resp.getFinanceId(),
            "dealNumber", resp.getDealNumber()
        );
    }

    private FinanceAppRequest toRequest(Map<String, Object> payload) {
        FinanceAppRequest req = mapper.convertValue(payload, FinanceAppRequest.class);
        if (req.getFinanceType() == null || req.getFinanceType().isBlank()) {
            req.setFinanceType("L");
        }
        return req;
    }

    private ImpactPreview buildPreview(FinanceAppResponse app, FinanceAppRequest req) {
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Submit %s finance app on deal %s — %s for %s months",
                        app.getFinanceTypeName() != null ? app.getFinanceTypeName() : req.getFinanceType(),
                        req.getDealNumber(),
                        money(req.getAmountRequested()),
                        req.getTermMonths()))
                .reversible(true)
                .build();
        p.addChange(String.format("+ FinanceApp (type=%s, status=NW)",
                app.getFinanceTypeName() != null ? app.getFinanceTypeName() : req.getFinanceType()));
        if (req.getLenderCode() != null && !req.getLenderCode().isBlank()) {
            p.addChange("Lender: " + req.getLenderCode() +
                    (app.getLenderName() != null ? " — " + app.getLenderName() : ""));
        }
        p.addChange("Amount requested: " + money(req.getAmountRequested()));
        if (req.getAprRequested() != null) {
            p.addChange("APR requested: " + req.getAprRequested().toPlainString() + "%");
        }
        p.addChange("Term: " + req.getTermMonths() + " months");
        if (app.getMonthlyPayment() != null && app.getMonthlyPayment().signum() > 0) {
            p.addChange("Est. monthly payment: " + money(app.getMonthlyPayment()));
        }
        if (req.getAprRequested() != null && req.getAprRequested().compareTo(new BigDecimal("15.0")) > 0) {
            p.addWarning("APR > 15% — double-check the credit tier and lender policy.");
        }
        p.setDetail(Map.of(
            "dealNumber", req.getDealNumber(),
            "financeType", req.getFinanceType(),
            "lenderCode", req.getLenderCode() == null ? "" : req.getLenderCode()
        ));
        return p;
    }

    private static String money(BigDecimal b) {
        if (b == null) return "$0.00";
        return String.format("$%,.2f", b);
    }
}
