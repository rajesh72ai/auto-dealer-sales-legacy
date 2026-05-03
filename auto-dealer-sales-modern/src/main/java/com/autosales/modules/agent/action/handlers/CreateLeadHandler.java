package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Prerequisite;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;

import java.util.List;
import com.autosales.modules.customer.dto.LeadRequest;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.service.CustomerLeadService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class CreateLeadHandler implements ActionHandler {

    private final CustomerLeadService leadService;
    private final PayloadValidator payloadValidator;

    @Override public String toolName() { return "create_lead"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.SALESPERSON, UserRole.MANAGER, UserRole.ADMIN, UserRole.CLERK, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/leads"; }
    @Override public boolean reversible() { return true; }

    @Override
    public List<Prerequisite> prerequisites() {
        return List.of(new Prerequisite(
                "customerId",                       // payload field gated
                "customer",                         // human-readable entity
                "list_customers",                   // finder
                "create_customer",                  // satisfier
                "customerId",                       // result field on the new CustomerResponse
                "Leads link to an existing customer record. If you don't already have one, "
                + "we can create the customer first; you'll be asked to confirm both steps.",
                List.of("firstName", "lastName", "phone", "addressLine1", "city", "stateCode", "zipCode")
        ));
    }

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
        Map<String, Object> filtered = new HashMap<>(payload);
        if (blank(filtered.get("dealerCode")))    filtered.put("dealerCode", user.getDealerCode());
        if (blank(filtered.get("assignedSales"))) filtered.put("assignedSales", user.getUserId());
        return payloadValidator.convertAndValidate(filtered, LeadRequest.class);
    }

    private static boolean blank(Object o) { return o == null || o.toString().isBlank(); }

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
