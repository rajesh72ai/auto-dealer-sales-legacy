package com.autosales.modules.agent;

import com.autosales.modules.customer.dto.CreditCheckResponse;
import com.autosales.modules.customer.dto.CustomerHistoryResponse;
import com.autosales.modules.customer.dto.CustomerResponse;
import com.autosales.modules.customer.entity.CustomerLead;
import com.autosales.modules.customer.repository.CustomerLeadRepository;
import com.autosales.modules.customer.service.CreditCheckService;
import com.autosales.modules.customer.service.CustomerService;
import com.autosales.modules.finance.dto.FinanceAppResponse;
import com.autosales.modules.finance.service.FinanceAppService;
import com.autosales.modules.registration.dto.RecallVehicleResponse;
import com.autosales.modules.registration.dto.WarrantyResponse;
import com.autosales.modules.registration.service.RecallService;
import com.autosales.modules.registration.service.WarrantyService;
import com.autosales.modules.sales.dto.DealResponse;
import com.autosales.modules.sales.service.DealService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Composite endpoints for the AI Agent. Each endpoint performs a whole workflow
 * server-side in one round-trip, reducing LLM tool-call overhead.
 */
@RestController
@RequestMapping("/api/composite")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR','AGENT_SERVICE')")
public class CompositeController {

    private static final Logger log = LoggerFactory.getLogger(CompositeController.class);
    private static final int DEAL_UW_STALL_DAYS = 7;

    private final CustomerService customerService;
    private final CustomerLeadRepository leadRepository;
    private final CreditCheckService creditCheckService;
    private final DealService dealService;
    private final FinanceAppService financeAppService;
    private final WarrantyService warrantyService;
    private final RecallService recallService;

    public CompositeController(CustomerService customerService,
                               CustomerLeadRepository leadRepository,
                               CreditCheckService creditCheckService,
                               DealService dealService,
                               FinanceAppService financeAppService,
                               WarrantyService warrantyService,
                               RecallService recallService) {
        this.customerService = customerService;
        this.leadRepository = leadRepository;
        this.creditCheckService = creditCheckService;
        this.dealService = dealService;
        this.financeAppService = financeAppService;
        this.warrantyService = warrantyService;
        this.recallService = recallService;
    }

    @GetMapping("/customer-360/{customerId}")
    public ResponseEntity<Map<String, Object>> customer360(@PathVariable Integer customerId,
                                                           @RequestParam(required = false) String dealerCode) {
        Map<String, Object> payload = new LinkedHashMap<>();
        CustomerResponse customer = customerService.findById(customerId);
        payload.put("customer", customer);

        CustomerHistoryResponse history = customerService.getHistory(customerId);
        payload.put("history", history);

        List<CustomerLead> leads = leadRepository.findByCustomer_CustomerId(customerId);
        List<Map<String, Object>> openLeads = new ArrayList<>();
        for (CustomerLead l : leads) {
            if (l.getLeadStatus() != null && !"CV".equals(l.getLeadStatus()) && !"LO".equals(l.getLeadStatus())) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("leadId", l.getLeadId());
                row.put("status", l.getLeadStatus());
                row.put("interestModel", l.getInterestModel());
                row.put("interestYear", l.getInterestYear());
                row.put("leadSource", l.getLeadSource());
                row.put("lastContactDt", l.getLastContactDt());
                row.put("followUpDate", l.getFollowUpDate());
                row.put("createdTs", l.getCreatedTs());
                openLeads.add(row);
            }
        }
        payload.put("openLeads", openLeads);

        List<Map<String, Object>> warrantySummary = new ArrayList<>();
        if (history != null && history.getDeals() != null) {
            int count = 0;
            for (CustomerHistoryResponse.DealSummary d : history.getDeals()) {
                if (count >= 3) break;
                if (d.getVin() == null) continue;
                try {
                    List<WarrantyResponse> warranties = warrantyService.findByVin(d.getVin());
                    for (WarrantyResponse w : warranties) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("vin", w.getVin());
                        row.put("type", w.getWarrantyType());
                        row.put("expiryDate", w.getExpiryDate());
                        warrantySummary.add(row);
                    }
                } catch (Exception ignore) {
                    // warranty not present — skip silently
                }
                count++;
            }
        }
        payload.put("warrantySummary", warrantySummary);

        Map<String, Object> credit = new LinkedHashMap<>();
        try {
            List<CreditCheckResponse> checks = creditCheckService.findByCustomerId(customerId);
            CreditCheckResponse mostRecent = checks.stream()
                    .filter(c -> c.getExpiryDate() != null)
                    .max(Comparator.comparing(CreditCheckResponse::getExpiryDate))
                    .orElse(null);
            credit.put("hasCheck", mostRecent != null);
            if (mostRecent != null) {
                boolean stale = mostRecent.getExpiryDate().isBefore(LocalDate.now());
                credit.put("creditId", mostRecent.getCreditId());
                credit.put("tier", mostRecent.getCreditTier());
                credit.put("score", mostRecent.getCreditScore());
                credit.put("expiryDate", mostRecent.getExpiryDate());
                credit.put("stale", stale);
            } else {
                credit.put("stale", true);
            }
        } catch (Exception e) {
            credit.put("hasCheck", false);
            credit.put("stale", true);
        }
        payload.put("credit", credit);

        List<String> suggestedActions = new ArrayList<>();
        if (Boolean.TRUE.equals(credit.get("stale"))) {
            suggestedActions.add("Run a fresh credit check — current check is stale or missing (>30 days).");
        }
        if (customer.getEmail() == null || customer.getEmail().isBlank() ||
                (customer.getCellPhone() == null || customer.getCellPhone().isBlank())) {
            suggestedActions.add("Incomplete contact info — request missing phone/email before next outreach.");
        }
        if (openLeads.isEmpty() && history != null && history.getTotalPurchases() != null &&
                history.getTotalPurchases() > 0) {
            suggestedActions.add("Loyalty candidate — past buyer with no open lead; consider a trade-in check-in call.");
        }
        payload.put("suggestedActions", suggestedActions);

        payload.put("dealerCode", dealerCode);
        return ResponseEntity.ok(payload);
    }

    @GetMapping("/deal-health/{dealNumber}")
    public ResponseEntity<Map<String, Object>> dealHealth(@PathVariable String dealNumber) {
        Map<String, Object> payload = new LinkedHashMap<>();
        List<String> findings = new ArrayList<>();
        String verdict = "GREEN";

        DealResponse deal = dealService.findByDealNumber(dealNumber);
        payload.put("deal", deal);

        // Stall check: deal in UW or PA beyond threshold
        if (("UW".equals(deal.getDealStatus()) || "PA".equals(deal.getDealStatus())) &&
                deal.getCreatedTs() != null) {
            long daysSince = ChronoUnit.DAYS.between(deal.getCreatedTs().toLocalDate(), LocalDate.now());
            if (daysSince > DEAL_UW_STALL_DAYS) {
                findings.add(String.format("Deal has been in %s status for %d days (threshold: %d).",
                        deal.getDealStatus(), daysSince, DEAL_UW_STALL_DAYS));
                verdict = downgrade(verdict, "YELLOW");
            }
        }

        // Finance app check
        Map<String, Object> financeBlock = new LinkedHashMap<>();
        try {
            // Try to find finance app for this deal — scan paginated list as services vary
            FinanceAppResponse app = null;
            try {
                // No direct getApplicationByDealNumber on some versions; fall back to listing.
                app = financeAppService.getApplication("FA-" + dealNumber);
            } catch (Exception ignore) {
                // Expected if naming convention differs — stay defensive.
            }
            if (app != null) {
                financeBlock.put("financeId", app.getFinanceId());
                financeBlock.put("status", app.getAppStatus());
                financeBlock.put("lender", app.getLenderName());
                financeBlock.put("aprApproved", app.getAprApproved());
                if ("DL".equals(deal.getDealStatus()) && !"APPROVED".equals(app.getAppStatus())) {
                    findings.add("Deal is DL but finance app is not APPROVED — compliance violation.");
                    verdict = downgrade(verdict, "RED");
                }
            } else {
                financeBlock.put("found", false);
                if ("DL".equals(deal.getDealStatus())) {
                    findings.add("Deal is DL but no finance application found — verify cash-deal status.");
                    verdict = downgrade(verdict, "YELLOW");
                }
            }
        } catch (Exception e) {
            financeBlock.put("error", "Finance lookup failed: " + e.getMessage());
        }
        payload.put("finance", financeBlock);

        // Recall check on VIN (internal DB)
        List<Map<String, Object>> recalls = new ArrayList<>();
        if (deal.getVin() != null) {
            try {
                List<RecallVehicleResponse> rv = recallService.findRecallsByVin(deal.getVin());
                for (RecallVehicleResponse r : rv) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("recallId", r.getRecallId());
                    row.put("status", r.getRecallStatus());
                    row.put("statusName", r.getRecallStatusName());
                    recalls.add(row);
                    String st = r.getRecallStatus();
                    if ("OPEN".equals(st) || "PENDING".equals(st) || "OP".equals(st) || "PN".equals(st)) {
                        findings.add("Open recall " + r.getRecallId() + " on VIN — blocks delivery.");
                        verdict = downgrade(verdict, "RED");
                    }
                }
            } catch (Exception ignore) {
                // No recall records — fine.
            }
        }
        payload.put("recalls", recalls);

        // Warranty on VIN
        if (deal.getVin() != null) {
            try {
                List<WarrantyResponse> warranties = warrantyService.findByVin(deal.getVin());
                payload.put("warranties", warranties);
            } catch (Exception ignore) {
                payload.put("warranties", Collections.emptyList());
            }
        }

        // Customer contact completeness
        if (deal.getCustomerId() != null) {
            try {
                CustomerResponse customer = customerService.findById(deal.getCustomerId());
                Map<String, Object> customerBlock = new LinkedHashMap<>();
                customerBlock.put("customerId", customer.getCustomerId());
                customerBlock.put("name", customer.getFullName());
                boolean hasPhone = (customer.getCellPhone() != null && !customer.getCellPhone().isBlank()) ||
                        (customer.getHomePhone() != null && !customer.getHomePhone().isBlank());
                boolean hasEmail = customer.getEmail() != null && !customer.getEmail().isBlank();
                customerBlock.put("hasPhone", hasPhone);
                customerBlock.put("hasEmail", hasEmail);
                if (!hasPhone && !hasEmail) {
                    findings.add("Customer has no phone and no email — contact risk.");
                    verdict = downgrade(verdict, "YELLOW");
                }
                payload.put("customer", customerBlock);
            } catch (Exception ignore) {
                // customer lookup issue — skip
            }
        }

        payload.put("verdict", verdict);
        payload.put("findings", findings);
        return ResponseEntity.ok(payload);
    }

    private String downgrade(String current, String candidate) {
        // Worst verdict wins: RED > YELLOW > GREEN
        if ("RED".equals(current) || "RED".equals(candidate)) return "RED";
        if ("YELLOW".equals(current) || "YELLOW".equals(candidate)) return "YELLOW";
        return "GREEN";
    }
}
