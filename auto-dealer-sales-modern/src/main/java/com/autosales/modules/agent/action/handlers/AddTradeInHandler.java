package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.sales.dto.TradeInRequest;
import com.autosales.modules.sales.dto.TradeInResponse;
import com.autosales.modules.sales.service.DealService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class AddTradeInHandler implements ActionHandler {

    private final DealService dealService;
    private final PayloadValidator payloadValidator;

    @Override public String toolName() { return "add_trade_in"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.SALESPERSON, UserRole.MANAGER, UserRole.ADMIN, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/deals/{dealNumber}/trade-in"; }
    @Override public boolean reversible() { return true; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String dealNumber = requireDealNumber(payload);
        TradeInRequest req = toRequest(payload, user);
        TradeInResponse tentative = dealService.addTradeIn(dealNumber, req);
        ImpactPreview preview = buildPreview(dealNumber, tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String dealNumber = requireDealNumber(payload);
        TradeInRequest req = toRequest(payload, user);
        return dealService.addTradeIn(dealNumber, req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof TradeInResponse resp)) return null;
        return Map.of(
            "action", "remove_trade_in",
            "tradeId", resp.getTradeId(),
            "dealNumber", resp.getDealNumber()
        );
    }

    private String requireDealNumber(Map<String, Object> payload) {
        Object raw = payload.get("dealNumber");
        if (raw == null || raw.toString().isBlank()) {
            throw new IllegalArgumentException("dealNumber is required in payload for add_trade_in");
        }
        return raw.toString();
    }

    private TradeInRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new java.util.HashMap<>(payload);
        filtered.remove("dealNumber");
        if (!filtered.containsKey("appraisedBy") || blank(filtered.get("appraisedBy"))) {
            filtered.put("appraisedBy", user.getUserId());
        }
        return payloadValidator.convertAndValidate(filtered, TradeInRequest.class);
    }

    private static boolean blank(Object o) {
        return o == null || o.toString().isBlank();
    }

    private ImpactPreview buildPreview(String dealNumber, TradeInResponse t, TradeInRequest req) {
        BigDecimal allowance = zero(t.getAllowanceAmt());
        BigDecimal payoff = zero(t.getPayoffAmt());
        BigDecimal netTrade = zero(t.getNetTrade());

        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Add trade-in to deal %s: %d %s %s",
                        dealNumber, req.getTradeYear(), req.getTradeMake(), req.getTradeModel()))
                .reversible(true)
                .build();
        p.addChange(String.format("+ TradeIn (%d %s %s, %s mi, cond=%s)",
                req.getTradeYear(), req.getTradeMake(), req.getTradeModel(),
                req.getOdometer(), req.getConditionCode()));
        p.addChange("ACV: " + money(t.getAcvAmount()));
        if (t.getOverAllow() != null && t.getOverAllow().signum() > 0) {
            p.addChange("Over-allowance: " + money(t.getOverAllow()));
        }
        p.addChange("Allowance total: " + money(allowance));
        if (payoff.signum() > 0) {
            p.addChange("Lien payoff: " + money(payoff) +
                    (t.getPayoffBank() != null ? " (" + t.getPayoffBank() + ")" : ""));
        }
        p.addChange("Net trade equity: " + money(netTrade));
        if (payoff.compareTo(allowance) > 0) {
            p.addWarning("Lien payoff exceeds allowance — trade is upside-down. Expect lower amount financed.");
        }

        p.setDetail(Map.of(
            "dealNumber", dealNumber,
            "tradeYear", req.getTradeYear(),
            "vin", req.getVin() == null ? "" : req.getVin()
        ));
        return p;
    }

    private static BigDecimal zero(BigDecimal b) { return b == null ? BigDecimal.ZERO : b; }
    private static String money(BigDecimal b) {
        if (b == null) return "$0.00";
        return String.format("$%,.2f", b);
    }
}
