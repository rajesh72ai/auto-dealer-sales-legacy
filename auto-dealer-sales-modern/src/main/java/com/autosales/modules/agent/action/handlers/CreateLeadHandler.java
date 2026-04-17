package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.customer.dto.LeadRequest;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.service.CustomerLeadService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class CreateLeadHandler implements ActionHandler {

    private final CustomerLeadService leadService;
    private final ObjectMapper mapper;

    @Override public String toolName() { return "create_lead"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.SALESPERSON, UserRole.MANAGER, UserRole.ADMIN, UserRole.CLERK, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/leads"; }
    @Override public boolean reversible() { return true; }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        LeadRequest req = toRequest(payload, user);
        LeadResponse tentative = leadService.create(req);
        ImpactPreview preview = buildPreview(tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        LeadRequest req = toRequest(payload, user);
        return leadService.create(req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof LeadResponse resp)) return null;
        return Map.of(
            "action", "close_lead",
            "leadId", resp.getLeadId(),
            "leadStatus", "DD"
        );
    }

    private LeadRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        LeadRequest req = mapper.convertValue(payload, LeadRequest.class);
        if (req.getDealerCode() == null || req.getDealerCode().isBlank()) {
            req.setDealerCode(user.getDealerCode());
        }
        if (req.getAssignedSales() == null || req.getAssignedSales().isBlank()) {
            req.setAssignedSales(user.getUserId());
        }
        return req;
    }

    private ImpactPreview buildPreview(LeadResponse lead, LeadRequest req) {
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Create new lead for %s (customer #%d) at %s",
                        lead.getCustomerName() != null ? lead.getCustomerName() : "customer",
                        req.getCustomerId(), req.getDealerCode()))
                .reversible(true)
                .build();
        p.addChange(String.format("+ CustomerLead (source=%s, status=NW)", req.getLeadSource()));
        if (req.getInterestModel() != null && !req.getInterestModel().isBlank()) {
            p.addChange("Interest: " + req.getInterestModel()
                    + (req.getInterestYear() != null ? " (" + req.getInterestYear() + ")" : ""));
        }
        p.addChange("Assigned to: " + req.getAssignedSales());
        if (req.getFollowUpDate() != null) {
            p.addChange("Follow-up: " + req.getFollowUpDate());
        }
        p.setDetail(Map.of(
            "customerId", req.getCustomerId(),
            "dealerCode", req.getDealerCode(),
            "leadSource", req.getLeadSource()
        ));
        return p;
    }
}
