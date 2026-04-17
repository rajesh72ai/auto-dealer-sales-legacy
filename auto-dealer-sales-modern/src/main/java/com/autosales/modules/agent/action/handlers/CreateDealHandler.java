package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.sales.dto.CreateDealRequest;
import com.autosales.modules.sales.dto.DealResponse;
import com.autosales.modules.sales.service.DealService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class CreateDealHandler implements ActionHandler {

    private final DealService dealService;
    private final PayloadValidator payloadValidator;

    @Override public String toolName() { return "create_deal"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.SALESPERSON, UserRole.MANAGER, UserRole.ADMIN, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/deals"; }
    @Override public boolean reversible() { return true; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        CreateDealRequest req = toRequest(payload, user);
        DealResponse tentative = dealService.createDeal(req);
        ImpactPreview preview = buildPreview(tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        CreateDealRequest req = toRequest(payload, user);
        return dealService.createDeal(req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof DealResponse resp)) return null;
        return Map.of(
            "action", "cancel_deal",
            "dealNumber", resp.getDealNumber(),
            "reason", "agent_undo"
        );
    }

    private CreateDealRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new HashMap<>(payload);
        if (blank(filtered.get("dealerCode")))    filtered.put("dealerCode", user.getDealerCode());
        if (blank(filtered.get("salespersonId"))) filtered.put("salespersonId", user.getUserId());
        if (blank(filtered.get("dealType")))      filtered.put("dealType", "R");
        return payloadValidator.convertAndValidate(filtered, CreateDealRequest.class);
    }

    private static boolean blank(Object o) { return o == null || o.toString().isBlank(); }

    private ImpactPreview buildPreview(DealResponse deal, CreateDealRequest req) {
        BigDecimal total = zeroIfNull(deal.getTotalPrice());
        BigDecimal subtotal = zeroIfNull(deal.getSubtotal());
        BigDecimal down = zeroIfNull(deal.getDownPayment());
        BigDecimal amountFinanced = zeroIfNull(deal.getAmountFinanced());

        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Create new deal for %s on %s",
                        nullSafe(deal.getCustomerName(), "customer #" + req.getCustomerId()),
                        nullSafe(deal.getVehicleDesc(), "VIN " + req.getVin())))
                .reversible(true)
                .build();

        p.addChange(String.format("+ SalesDeal (dealer=%s, status=WS, type=%s)",
                req.getDealerCode(), req.getDealType()));
        p.addChange(String.format("Vehicle: %s — %s",
                nullSafe(deal.getVehicleDesc(), req.getVin()),
                formatMoney(deal.getVehiclePrice())));
        if (deal.getSalespersonName() != null) {
            p.addChange("Salesperson: " + deal.getSalespersonName());
        }
        p.addChange("Subtotal: " + formatMoney(subtotal));
        p.addChange("Total price: " + formatMoney(total));
        if (down.signum() > 0) {
            p.addChange("Down payment: " + formatMoney(down));
        }
        p.addChange("Amount financed: " + formatMoney(amountFinanced));

        if (deal.getVehiclePrice() == null || deal.getVehiclePrice().signum() == 0) {
            p.addWarning("No PriceMaster entry for this vehicle — pricing will be zero until you adjust it.");
        }

        p.setDetail(Map.of(
            "customerId", req.getCustomerId(),
            "vin", req.getVin(),
            "dealerCode", req.getDealerCode(),
            "dealType", req.getDealType(),
            "salespersonId", req.getSalespersonId()
        ));
        return p;
    }

    private static BigDecimal zeroIfNull(BigDecimal b) { return b == null ? BigDecimal.ZERO : b; }
    private static String nullSafe(String s, String fallback) { return (s == null || s.isBlank()) ? fallback : s; }
    private static String formatMoney(BigDecimal b) {
        if (b == null) return "$0.00";
        return String.format("$%,.2f", b);
    }
}
