package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.ActionHandler;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.PayloadValidator;
import com.autosales.modules.agent.action.Tier;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.customer.dto.CustomerRequest;
import com.autosales.modules.customer.dto.CustomerResponse;
import com.autosales.modules.customer.service.CustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Tier A write that creates a Customer record. Added in B-prereq as the
 * satisfier for {@code create_lead}'s {@code customerId} prerequisite —
 * but it's a first-class action in its own right; users can propose
 * customer creation directly.
 *
 * <p>Defaults the dealerCode and customerType when not provided so the
 * agent can chain it after a brief user-supplied data form (the
 * PrerequisiteGapCard's input fields) without requiring all 18 columns.
 */
@Component
@RequiredArgsConstructor
public class CreateCustomerHandler implements ActionHandler {

    private final CustomerService customerService;
    private final PayloadValidator payloadValidator;

    @Override public String toolName() { return "create_customer"; }
    @Override public Tier tier()       { return Tier.A; }
    @Override public Set<UserRole> allowedRoles() {
        return Set.of(UserRole.SALESPERSON, UserRole.MANAGER, UserRole.ADMIN, UserRole.CLERK, UserRole.OPERATOR);
    }
    @Override public String endpointDescriptor() { return "POST /api/customers"; }
    @Override public boolean reversible() { return true; }

    @Override
    public String payloadSchemaHint() {
        return """
                  - firstName (required, max 30 chars)
                  - lastName (required, max 30 chars)
                  - addressLine1 (required, max 50 chars — street number + name, e.g. "123 Main Street")
                  - city (required, max 30 chars)
                  - stateCode (required, EXACTLY 2 uppercase letters — e.g. "MI" not "Michigan")
                  - zipCode (required, max 10 chars)
                  - cellPhone (optional, exactly 10 digits, NO punctuation — e.g. "2485559999" not "248-555-9999")
                  - email (optional, valid email)
                  - customerType (optional, defaults to "I" for Individual; "B"=Business, "F"=Fleet)
                  - dealerCode (optional, defaults to caller's dealer)
                When asking the user for these fields, list them by EXACT name above so they can supply each one separately.""";
    }

    @Override
    @Transactional(rollbackFor = DryRunRollback.class)
    public ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        CustomerRequest req = toRequest(payload, user);
        CustomerResponse tentative = customerService.create(req);
        ImpactPreview preview = buildPreview(tentative, req);
        throw new DryRunRollback(preview);
    }

    @Override
    public Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        CustomerRequest req = toRequest(payload, user);
        return customerService.create(req);
    }

    @Override
    public Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        if (!(executeResult instanceof CustomerResponse resp)) return null;
        return Map.of(
            "action", "delete_customer",
            "customerId", resp.getCustomerId()
        );
    }

    private CustomerRequest toRequest(Map<String, Object> payload, CurrentUserContext.Snapshot user) {
        Map<String, Object> filtered = new HashMap<>(payload);
        // Sensible defaults so the prereq gap-card form can ask only for the
        // essentials. The user can still override any of these.
        if (blank(filtered.get("dealerCode")))    filtered.put("dealerCode", user.getDealerCode());
        if (blank(filtered.get("assignedSales"))) filtered.put("assignedSales", user.getUserId());
        if (blank(filtered.get("customerType"))) filtered.put("customerType", "I"); // Individual
        // "phone" is a friendly alias used by the agent; map it to cellPhone if cellPhone not set.
        Object phone = filtered.get("phone");
        if (phone != null && blank(filtered.get("cellPhone"))) {
            filtered.put("cellPhone", phone.toString().replaceAll("[^0-9]", ""));
        }
        return payloadValidator.convertAndValidate(filtered, CustomerRequest.class);
    }

    private static boolean blank(Object o) { return o == null || o.toString().isBlank(); }

    private ImpactPreview buildPreview(CustomerResponse cust, CustomerRequest req) {
        ImpactPreview p = ImpactPreview.builder()
                .toolName(toolName())
                .tier(tier().getCode())
                .summary(String.format("Create new customer %s %s at %s",
                        req.getFirstName(), req.getLastName(), req.getDealerCode()))
                .reversible(true)
                .build();
        p.addChange(String.format("+ Customer (type=%s)", req.getCustomerType()));
        p.addChange(String.format("Address: %s, %s, %s %s",
                req.getAddressLine1(), req.getCity(), req.getStateCode(), req.getZipCode()));
        if (req.getCellPhone() != null) p.addChange("Cell: " + req.getCellPhone());
        if (req.getEmail() != null)    p.addChange("Email: " + req.getEmail());
        p.setDetail(Map.of(
            "firstName", req.getFirstName(),
            "lastName", req.getLastName(),
            "dealerCode", req.getDealerCode()
        ));
        return p;
    }
}
