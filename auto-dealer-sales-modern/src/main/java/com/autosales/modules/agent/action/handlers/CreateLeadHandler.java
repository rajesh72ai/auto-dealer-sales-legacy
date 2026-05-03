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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class CreateLeadHandler implements ActionHandler {

    private static final Logger log = LoggerFactory.getLogger(CreateLeadHandler.class);

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
    public String payloadSchemaHint() {
        return """
                  - customerId (required, INTEGER — must reference an EXISTING customer; resolve via list_customers/find_customer first)
                  - dealerCode (required, max 5 chars; defaults to caller's dealer if omitted)
                  - leadSource (required, EXACTLY 3 uppercase letters — one of: WEB (web inquiry), WLK (walk-in), REF (referral), ADV (advertisement), PHN (phone). Do NOT pass long forms like "REFERRAL" or "WALK_IN" — they will be rejected by validation.)
                  - interestModel (optional, max 6 chars — internal model code like "F150XL")
                  - interestYear (optional, integer year e.g. 2026)
                  - followUpDate (optional, YYYY-MM-DD)
                  - assignedSales (optional, max 8 chars, salesperson user id; defaults to caller)
                  - notes (optional, max 200 chars)""";
    }

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

        // dealerCode default — caller's dealer
        if (blank(filtered.get("dealerCode"))) {
            filtered.put("dealerCode", user.getDealerCode());
        }

        // assignedSales default — caller's user id, hard-fallback to "SYSTEM".
        // Hardened 2026-05-03 after live test produced "must not be blank" on
        // assignedSales because Gemini either omitted or sent a value that
        // looked non-blank but didn't pass downstream validation. Defenses:
        //   - blank() handles null, "", whitespace, AND the literal string "null"
        //   - if user.getUserId() is itself blank, fall through to "SYSTEM"
        //   - clamp to LeadRequest.assignedSales @Size(max=8)
        Object incoming = filtered.get("assignedSales");
        boolean defaultFilled = false;
        if (blank(incoming)) {
            String fallback = user != null ? user.getUserId() : null;
            if (blank(fallback)) fallback = "SYSTEM";
            if (fallback.length() > 8) fallback = fallback.substring(0, 8);
            filtered.put("assignedSales", fallback);
            defaultFilled = true;
        } else {
            // Defensive truncation: LLM sometimes pastes the full salesperson
            // name (e.g. "Kumaran Thandavamurthy") into this field; clamp to 8.
            String s = incoming.toString().trim();
            if (s.length() > 8) {
                log.warn("CreateLeadHandler: truncating LLM-supplied assignedSales '{}' to 8 chars", s);
                filtered.put("assignedSales", s.substring(0, 8));
                defaultFilled = true;
            }
        }
        if (defaultFilled) {
            log.info("CreateLeadHandler: default-fill triggered for assignedSales (final value='{}', user.userId='{}')",
                    filtered.get("assignedSales"),
                    user != null ? user.getUserId() : "(null user)");
        }
        return payloadValidator.convertAndValidate(filtered, LeadRequest.class);
    }

    /**
     * Robust blank check — handles {@code null}, empty string, whitespace, AND
     * the literal text {@code "null"} which LLMs sometimes emit verbatim when
     * they have no value to supply.
     */
    private static boolean blank(Object o) {
        if (o == null) return true;
        String s = o.toString().trim();
        return s.isEmpty() || "null".equalsIgnoreCase(s);
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
