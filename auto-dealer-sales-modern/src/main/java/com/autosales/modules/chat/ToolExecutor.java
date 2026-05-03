package com.autosales.modules.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Component
public class ToolExecutor {

    private static final Logger log = LoggerFactory.getLogger(ToolExecutor.class);
    private static final int MAX_RESPONSE_LENGTH = 4000;

    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public ToolExecutor(@Value("${api.key}") String apiKey,
                        @Value("${server.port:8480}") int port,
                        ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
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
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));
                case "get_vehicle" -> get("/api/vehicles/%s", arg(args, "vin"));
                case "decode_vin" -> get("/api/vehicles/%s/decode", arg(args, "vin"));

                // Customers
                case "list_customers" -> get("/api/customers?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));
                case "get_customer" -> get("/api/customers/%s", arg(args, "customerId"));
                case "find_customer" -> get("/api/customers/search?type=LN&value=%s&dealerCode=%s&page=0&size=20",
                        arg(args, "lastName"), arg(args, "dealerCode"));

                // Deals
                case "list_deals" -> get("/api/deals?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));
                case "get_deal" -> get("/api/deals/%s", arg(args, "dealNumber"));

                // Stock
                case "get_stock_summary" -> get("/api/stock/summary?dealerCode=%s", arg(args, "dealerCode"));
                case "get_stock_positions" -> get("/api/stock/positions?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));
                case "get_stock_aging" -> get("/api/stock/aging?dealerCode=%s", arg(args, "dealerCode"));
                case "get_stock_alerts" -> get("/api/stock/alerts?dealerCode=%s", arg(args, "dealerCode"));

                // Floor Plan
                case "get_floorplan_vehicles" -> get("/api/floorplan/vehicles?dealerCode=%s", arg(args, "dealerCode"));
                case "get_floorplan_exposure" -> get("/api/floorplan/reports/exposure?dealerCode=%s", arg(args, "dealerCode"));

                // Finance
                case "list_finance_apps" -> get("/api/finance/applications?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));

                // Registration & Warranty
                case "list_registrations" -> get("/api/registrations?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));
                case "get_warranty_by_vin" -> get("/api/warranties/by-vin/%s", arg(args, "vin"));
                case "list_warranty_claims" -> get("/api/warranty-claims?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));
                case "list_recalls" -> get("/api/recalls?page=%s&size=%s",
                        arg(args, "page", "0"), arg(args, "size", "10"));

                // Leads
                case "list_leads" -> get("/api/leads?dealerCode=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "page", "0"), arg(args, "size", "10"));

                // Production & Shipments
                case "list_shipments" -> get("/api/production/shipments?dealer=%s&status=%s&page=%s&size=%s",
                        arg(args, "dealerCode"), arg(args, "status", ""), arg(args, "page", "0"), arg(args, "size", "10"));
                case "get_shipment" -> get("/api/production/shipments/%s", arg(args, "shipmentId"));

                // Batch & Reports
                case "get_batch_jobs" -> get("/api/batch/jobs");
                case "get_daily_sales_report" -> get("/api/batch/reports/daily-sales?dealerCode=%s",
                        arg(args, "dealerCode"));
                case "get_commissions_report" -> get("/api/batch/reports/commissions?dealerCode=%s",
                        arg(args, "dealerCode"));

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

                default -> "Unknown tool: " + toolName;
            };
            return truncate(result);
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

    private String truncate(String response) {
        if (response != null && response.length() > MAX_RESPONSE_LENGTH) {
            return response.substring(0, MAX_RESPONSE_LENGTH) + "\n... (truncated, " + response.length() + " chars total)";
        }
        return response;
    }
}
