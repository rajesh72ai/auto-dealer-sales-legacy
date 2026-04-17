package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.registration.dto.WarrantyClaimRequest;
import com.autosales.modules.registration.dto.WarrantyClaimResponse;
import com.autosales.modules.registration.service.WarrantyClaimService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class CloseWarrantyClaimHandler implements ActionHandler {

    private final WarrantyClaimService warrantyClaimService;
    private final ObjectMapper mapper;

    @Override public String toolName() { return "close_warranty_claim"; }
    @Override public Tier tier()       { return Tier.B; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.MANAGER, UserRole.ADMIN, UserRole.FINANCE);
    }
    @Override public String endpointDescriptor() { return "PUT /api/warranty-claims/{claimNumber}"; }
    @Override public boolean reversible() { return false; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String claimNumber = requireClaimNumber(payload);
        WarrantyClaimRequest req = toRequest(payload, user);
        WarrantyClaimResponse tentative = warrantyClaimService.update(claimNumber, req);
        ImpactPreview preview = buildPreview(claimNumber, tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        String claimNumber = requireClaimNumber(payload);
        WarrantyClaimRequest req = toRequest(payload, user);
        return warrantyClaimService.update(claimNumber, req);
    }

    private String requireClaimNumber(Map<String, Object> payload) {
        Object raw = payload.get("claimNumber");
        if (raw == null || raw.toString().isBlank()) {
            throw new IllegalArgumentException("claimNumber is required in payload for close_warranty_claim");
        }
        return raw.toString();
    }

    private WarrantyClaimRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new java.util.HashMap<>(payload);
        filtered.remove("claimNumber");
        WarrantyClaimRequest req = mapper.convertValue(filtered, WarrantyClaimRequest.class);
        if (req.getDealerCode() == null || req.getDealerCode().isBlank()) {
            req.setDealerCode(user.getDealerCode());
        }
        if (req.getClaimStatus() == null || req.getClaimStatus().isBlank()) {
            req.setClaimStatus("CL");
        }
        return req;
    }

    private ImpactPreview buildPreview(String claimNumber, WarrantyClaimResponse resp, WarrantyClaimRequest req) {
        BigDecimal total = resp.getTotalClaim() != null ? resp.getTotalClaim() : BigDecimal.ZERO;
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Close warranty claim %s — total %s",
                        claimNumber, money(total)))
                .reversible(false)
                .build();
        p.addChange(String.format("Claim status → %s (%s)",
                resp.getClaimStatus() != null ? resp.getClaimStatus() : req.getClaimStatus(),
                resp.getClaimStatusName() != null ? resp.getClaimStatusName() : "Closed"));
        if (resp.getLaborAmt() != null) p.addChange("Labor: " + money(resp.getLaborAmt()));
        if (resp.getPartsAmt() != null) p.addChange("Parts: " + money(resp.getPartsAmt()));
        p.addChange("Total: " + money(total));
        if (req.getNotes() != null && !req.getNotes().isBlank()) {
            p.addChange("Notes: " + req.getNotes());
        }
        p.addWarning("A closed claim cannot be reopened — ensure all amounts are final before confirming.");
        p.setDetail(Map.of(
            "claimNumber", claimNumber,
            "newStatus", req.getClaimStatus()
        ));
        return p;
    }

    private static String money(BigDecimal b) {
        if (b == null) return "$0.00";
        return String.format("$%,.2f", b);
    }
}
