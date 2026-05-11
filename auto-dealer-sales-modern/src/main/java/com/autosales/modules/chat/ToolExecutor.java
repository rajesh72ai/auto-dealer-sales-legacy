package com.autosales.modules.chat;

import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.discovery.AutoDescriptorRouter;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class ToolExecutor {

    private static final Logger log = LoggerFactory.getLogger(ToolExecutor.class);
    private static final int MAX_RESPONSE_LENGTH = 4000;

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final AutoDescriptorRouter autoRouter;
    private final CurrentUserContext currentUserContext;

    public ToolExecutor(@Value("${api.key}") String apiKey,
                        @Value("${server.port:8480}") int port,
                        ObjectMapper objectMapper,
                        AutoDescriptorRouter autoRouter,
                        CurrentUserContext currentUserContext) {
        this.objectMapper = objectMapper;
        this.autoRouter = autoRouter;
        this.currentUserContext = currentUserContext;
        this.restClient = RestClient.builder()
                .baseUrl("http://localhost:" + port)
                .defaultHeader("X-API-Key", apiKey)
                .build();
    }

    public String execute(String toolName, Map<String, Object> args) {
        try {
            String result = switch (toolName) {
                // Dealers
                case "list_dealers" -> get("/api/admin/dealers?page=%s&size=%s",
                        arg(args, "page", "0"), arg(args, "size", "20"));
                case "get_dealer" -> get("/api/admin/dealers/%s", arg(args, "dealerCode"));

                // Vehicles
                case "list_vehicles" -> get("/api/vehicles?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));
                case "get_vehicle" -> get("/api/vehicles/%s", arg(args, "vin"));
                case "decode_vin" -> get("/api/vehicles/%s/decode", arg(args, "vin"));

                // Customers
                case "list_customers" -> get("/api/customers?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));
                case "get_customer" -> get("/api/customers/%s", arg(args, "customerId"));
                case "find_customer" -> findCustomer(args);

                // Deals
                case "list_deals" -> get("/api/deals?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));
                case "get_deal" -> get("/api/deals/%s", arg(args, "dealNumber"));

                // Stock
                case "get_stock_summary" -> get("/api/stock/summary?dealerCode=%s", dealerCodeOrSession(args));
                case "get_stock_positions" -> get("/api/stock/positions?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));
                case "get_stock_aging" -> get("/api/stock/aging?dealerCode=%s", dealerCodeOrSession(args));
                case "get_stock_alerts" -> get("/api/stock/alerts?dealerCode=%s", dealerCodeOrSession(args));

                // Floor Plan
                case "get_floorplan_vehicles" -> get("/api/floorplan/vehicles?dealerCode=%s", dealerCodeOrSession(args));
                case "get_floorplan_exposure" -> get("/api/floorplan/reports/exposure?dealerCode=%s", dealerCodeOrSession(args));

                // Finance
                case "list_finance_apps" -> get("/api/finance/applications?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));

                // Registration & Warranty
                case "list_registrations" -> get("/api/registrations?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));
                case "get_warranty_by_vin" -> get("/api/warranties/by-vin/%s", arg(args, "vin"));
                case "list_warranty_claims" -> get("/api/warranty-claims?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));
                case "list_recalls" -> get("/api/recalls?page=%s&size=%s",
                        arg(args, "page", "0"), arg(args, "size", "50"));

                // Leads
                case "list_leads" -> get("/api/leads?dealerCode=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "page", "0"), arg(args, "size", "50"));

                // Production & Shipments
                case "list_shipments" -> get("/api/production/shipments?dealer=%s&status=%s&page=%s&size=%s",
                        dealerCodeOrSession(args), arg(args, "status", ""), arg(args, "page", "0"), arg(args, "size", "50"));
                case "get_shipment" -> get("/api/production/shipments/%s", arg(args, "shipmentId"));

                // Batch & Reports
                case "get_batch_jobs" -> get("/api/batch/jobs");
                case "get_daily_sales_report" -> get("/api/batch/reports/daily-sales?dealerCode=%s&startDate=%s&endDate=%s",
                        dealerCodeOrSession(args), arg(args, "startDate"), arg(args, "endDate"));
                case "get_commissions_report" -> get("/api/batch/reports/commissions?dealerCode=%s&payPeriod=%s",
                        dealerCodeOrSession(args), arg(args, "payPeriod"));

                // Calculators & Actions
                case "calculate_loan" -> post("/api/finance/applications/loan-calculator", args);
                case "calculate_lease" -> post("/api/finance/applications/lease-calculator", args);
                case "create_lead" -> post("/api/leads", args);
                case "run_credit_check" -> post("/api/credit-checks", args);

                // Incentives (read)
                case "list_incentives" -> get("/api/admin/incentives?type=%s&active=%s&page=%s&size=%s",
                        arg(args, "type", ""), arg(args, "active", ""),
                        arg(args, "page", "0"), arg(args, "size", "20"));
                case "get_incentive" -> get("/api/admin/incentives/%s", arg(args, "programCode"));

                // NHTSA federal data (live external)
                case "nhtsa_recall_lookup" -> get("/api/nhtsa/recalls?vin=%s", arg(args, "vin"));
                case "nhtsa_vin_decode"    -> get("/api/nhtsa/decode?vin=%s", arg(args, "vin"));

                // Capability Gap Logging (reusable across apps)
                case "log_capability_gap" -> post("/api/capability-gaps", args);

                // Auto-discovered tool fallback (B-discovery Path A) — synthetic
                // names like "get_api_admin_lot-locations" are routed by the
                // descriptor index built from ToolDescriptorExtractor at startup.
                // Returns "Unknown tool: ..." only when the name isn't in either
                // the curated switch above OR the synthetic index.
                default -> autoRouter.route(toolName, args)
                        .orElse("Unknown tool: " + toolName);
            };
            return truncate(result);
        } catch (org.springframework.web.client.HttpStatusCodeException httpEx) {
            // Surface 4xx response body so schema-drift bugs (LLM omits a
            // required @RequestParam) appear as actionable text instead of a
            // vague "internal server error" the model invents from a 400.
            String body = httpEx.getResponseBodyAsString();
            log.warn("Tool HTTP error: tool={}, status={}, body={}",
                    toolName, httpEx.getStatusCode(), body);
            return "Error " + httpEx.getStatusCode().value() + ": "
                    + (body == null || body.isBlank() ? httpEx.getMessage() : body);
        } catch (Exception e) {
            log.warn("Tool execution failed: tool={}, error={}", toolName, e.getMessage());
            return "Error: " + e.getMessage();
        }
    }

    private String get(String urlTemplate, Object... args) {
        String url = String.format(urlTemplate, args);
        log.debug("Tool GET: {}", url);
        return restClient.get().uri(url).retrieve().body(String.class);
    }

    private String post(String url, Map<String, Object> body) {
        log.debug("Tool POST: {} body={}", url, body);
        return restClient.post()
                .uri(url)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);
    }

    private String arg(Map<String, Object> args, String key) {
        Object val = args.get(key);
        return val != null ? val.toString() : "";
    }

    private String arg(Map<String, Object> args, String key, String defaultValue) {
        Object val = args.get(key);
        return val != null ? val.toString() : defaultValue;
    }

    /**
     * Resolve {@code dealerCode}: prefer the explicit arg supplied by the LLM,
     * fall back to the caller's own dealership from {@link CurrentUserContext}.
     * Returns "" when neither is available — callers downstream will surface
     * the resulting 400 from the controller.
     *
     * <p>Why this exists: tool schemas mark {@code dealerCode} optional so the
     * LLM doesn't waste a turn asking the user for a value the system already
     * knows. This helper is what makes that promise true at execution time.
     */
    private String dealerCodeOrSession(Map<String, Object> args) {
        String explicit = arg(args, "dealerCode");
        if (!explicit.isBlank()) return explicit;
        try {
            String fromSession = currentUserContext.current().getDealerCode();
            return fromSession != null ? fromSession : "";
        } catch (Exception e) {
            log.debug("dealerCodeOrSession: no session dealer available ({})", e.getMessage());
            return "";
        }
    }

    /**
     * find_customer with name-field fallback. The LLM can pass an ambiguous
     * single token (e.g. "Aditya") in either {@code lastName} or
     * {@code firstName} without asking the user to disambiguate. We perform
     * up to TWO searches (LN and FN) and merge the results.
     *
     * <ul>
     *   <li>Both lastName + firstName supplied: search by lastName only —
     *       the firstName narrows in the LLM's reasoning.</li>
     *   <li>Only lastName: search LN; ALSO search FN with the same token to
     *       catch the "user gave a first name, LLM stuffed it in lastName"
     *       case. Merge.</li>
     *   <li>Only firstName: symmetric to above.</li>
     *   <li>Neither: return an error message (user truly gave no name).</li>
     * </ul>
     */
    private String findCustomer(Map<String, Object> args) {
        String dealer = dealerCodeOrSession(args);
        String last = arg(args, "lastName");
        String first = arg(args, "firstName");

        if (dealer.isBlank()) {
            return "Error: dealerCode missing and no caller dealership in session — cannot search customers.";
        }
        if (last.isBlank() && first.isBlank()) {
            return "Error: provide at least firstName or lastName for find_customer.";
        }

        boolean bothNames = !last.isBlank() && !first.isBlank();

        String lnBody = null;
        String fnBody = null;
        try {
            if (!last.isBlank()) {
                lnBody = customerSearch(dealer, "LN", last);
            }
            if (bothNames) {
                // Both supplied — LN is enough; LLM can filter by first.
            } else if (!first.isBlank()) {
                fnBody = customerSearch(dealer, "FN", first);
            } else {
                // Only lastName given — also try it as a firstName for
                // ambiguous single tokens like "Aditya".
                fnBody = customerSearch(dealer, "FN", last);
            }
        } catch (Exception e) {
            log.warn("find_customer search failed: {}", e.getMessage());
            return "Error: customer search failed: " + e.getMessage();
        }

        return mergeCustomerSearchResults(lnBody, fnBody);
    }

    private String customerSearch(String dealer, String type, String value) {
        String encodedValue = URLEncoder.encode(value, StandardCharsets.UTF_8);
        String encodedDealer = URLEncoder.encode(dealer, StandardCharsets.UTF_8);
        String url = "/api/customers/search?type=" + type
                + "&value=" + encodedValue
                + "&dealerCode=" + encodedDealer
                + "&page=0&size=20";
        log.debug("Tool GET (find_customer leg): {}", url);
        return restClient.get().uri(url).retrieve().body(String.class);
    }

    /**
     * Merge two paginated customer-search responses into one envelope,
     * de-duplicating by {@code customerId}. Either input may be {@code null}
     * (when only one search leg ran). Synthesizes new pagination metadata
     * because we no longer correspond to a single repository page.
     */
    @SuppressWarnings("unchecked")
    private String mergeCustomerSearchResults(String lnBody, String fnBody) {
        try {
            List<Map<String, Object>> merged = new java.util.ArrayList<>();
            Set<Object> seenIds = new LinkedHashSet<>();

            for (String body : List.of(
                    lnBody == null ? "" : lnBody,
                    fnBody == null ? "" : fnBody)) {
                if (body.isBlank()) continue;
                Map<String, Object> parsed = objectMapper.readValue(body,
                        new TypeReference<Map<String, Object>>() {});
                Object content = parsed.get("content");
                if (!(content instanceof List<?> list)) continue;
                for (Object item : list) {
                    if (!(item instanceof Map<?, ?> row)) continue;
                    Object id = row.get("customerId");
                    if (id != null && seenIds.add(id)) {
                        merged.add((Map<String, Object>) row);
                    }
                }
            }

            Map<String, Object> envelope = new LinkedHashMap<>();
            envelope.put("status", "SUCCESS");
            envelope.put("message", "OK");
            envelope.put("content", merged);
            envelope.put("page", 0);
            envelope.put("totalPages", merged.isEmpty() ? 0 : 1);
            envelope.put("totalElements", merged.size());
            return objectMapper.writeValueAsString(envelope);
        } catch (Exception e) {
            log.warn("merge customer search failed, returning raw LN body: {}", e.getMessage());
            return lnBody != null ? lnBody : (fnBody != null ? fnBody : "Error: customer merge failed");
        }
    }

    private String truncate(String response) {
        if (response != null && response.length() > MAX_RESPONSE_LENGTH) {
            return response.substring(0, MAX_RESPONSE_LENGTH) + "\n... (truncated, " + response.length() + " chars total)";
        }
        return response;
    }
}
