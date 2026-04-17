package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.vehicle.dto.ShipmentDeliverRequest;
import com.autosales.modules.vehicle.dto.ShipmentResponse;
import com.autosales.modules.vehicle.service.ProductionLogisticsService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class MarkArrivedHandler implements ActionHandler {

    private final ProductionLogisticsService logisticsService;
    private final ObjectMapper mapper;

    @Override public String toolName() { return "mark_arrived"; }
    @Override public Tier tier()       { return Tier.B; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.MANAGER, UserRole.ADMIN, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/production/shipments/{id}/deliver"; }
    @Override public boolean reversible() { return false; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String shipmentId = requireShipmentId(payload);
        ShipmentDeliverRequest req = toRequest(payload, user);
        ShipmentResponse tentative = logisticsService.deliverShipment(shipmentId, req);
        ImpactPreview preview = buildPreview(shipmentId, tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String shipmentId = requireShipmentId(payload);
        ShipmentDeliverRequest req = toRequest(payload, user);
        return logisticsService.deliverShipment(shipmentId, req);
    }

    private String requireShipmentId(Map<String, Object> payload) {
        Object raw = payload.get("shipmentId");
        if (raw == null || raw.toString().isBlank()) {
            throw new IllegalArgumentException("shipmentId is required in payload for mark_arrived");
        }
        return raw.toString();
    }

    private ShipmentDeliverRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new java.util.HashMap<>(payload);
        filtered.remove("shipmentId");
        ShipmentDeliverRequest req = mapper.convertValue(filtered, ShipmentDeliverRequest.class);
        if (req.getReceivedBy() == null || req.getReceivedBy().isBlank()) {
            req.setReceivedBy(user.getUserId());
        }
        return req;
    }

    private ImpactPreview buildPreview(String shipmentId, ShipmentResponse resp, ShipmentDeliverRequest req) {
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Mark shipment %s as delivered (%d vehicles → inventory)",
                        shipmentId, resp.getVehicleCount() != null ? resp.getVehicleCount() : 0))
                .reversible(false)
                .build();
        p.addChange(String.format("Shipment status: %s → DL (Delivered)",
                resp.getShipmentStatus() != null ? resp.getShipmentStatus() : "prior"));
        p.addChange("ShipmentVehicles: all marked DL");
        p.addChange("Vehicles moved into dealer inventory (AV status)");
        p.addChange("PDI schedule created for each vehicle (SC status)");
        p.addChange("Received by: " + req.getReceivedBy());
        p.addWarning("This action is NOT reversible — use only when physical delivery is confirmed.");
        p.setDetail(Map.of(
            "shipmentId", shipmentId,
            "destDealer", resp.getDestDealer() == null ? "" : resp.getDestDealer()
        ));
        return p;
    }
}
