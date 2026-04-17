package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.vehicle.dto.TransferRequest;
import com.autosales.modules.vehicle.dto.TransferResponse;
import com.autosales.modules.vehicle.service.StockTransferService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class TransferStockHandler implements ActionHandler {

    private final StockTransferService transferService;
    private final PayloadValidator payloadValidator;

    @Override public String toolName() { return "transfer_stock"; }
    @Override public Tier tier()       { return Tier.B; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.MANAGER, UserRole.ADMIN);
    }
    @Override public String endpointDescriptor() { return "POST /api/stock/transfers"; }
    @Override public boolean reversible() { return true; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        TransferRequest req = toRequest(payload, user);
        TransferResponse tentative = transferService.requestTransfer(req);
        ImpactPreview preview = buildPreview(tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        TransferRequest req = toRequest(payload, user);
        return transferService.requestTransfer(req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof TransferResponse resp)) return null;
        return Map.of(
            "action", "cancel_transfer",
            "transferId", resp.getTransferId()
        );
    }

    private TransferRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new HashMap<>(payload);
        if (blank(filtered.get("requestedBy"))) filtered.put("requestedBy", user.getUserId());
        if (blank(filtered.get("fromDealer")))  filtered.put("fromDealer", user.getDealerCode());
        return payloadValidator.convertAndValidate(filtered, TransferRequest.class);
    }

    private static boolean blank(Object o) { return o == null || o.toString().isBlank(); }

    private ImpactPreview buildPreview(TransferResponse t, TransferRequest req) {
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Request transfer of VIN %s from %s → %s",
                        req.getVin(), req.getFromDealer(), req.getToDealer()))
                .reversible(true)
                .build();
        p.addChange("+ StockTransfer (status=RQ, awaiting manager approval on destination side)");
        if (t.getVehicleDesc() != null) p.addChange("Vehicle: " + t.getVehicleDesc());
        p.addChange("Requested by: " + req.getRequestedBy());
        if (req.getReason() != null) p.addChange("Reason: " + req.getReason());
        p.addWarning("Inventory does NOT move now — this creates a pending transfer. " +
                "approveTransfer + completeTransfer are separate steps.");
        p.setDetail(Map.of(
            "fromDealer", req.getFromDealer(),
            "toDealer", req.getToDealer(),
            "vin", req.getVin()
        ));
        return p;
    }
}
