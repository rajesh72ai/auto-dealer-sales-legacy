package com.autosales.modules.chat;

import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class ToolRegistry {

    private final List<Map<String, Object>> toolDefinitions = new ArrayList<>();

    public ToolRegistry() {
        // --- Dealers & Admin ---
        register("list_dealers", "List all dealers with pagination",
                props(optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 20)")));

        register("get_dealer", "Get a specific dealer by code",
                props(required("dealerCode", "string", "Dealer code, e.g. DLR01")));

        // --- Vehicles ---
        register("list_vehicles", "List vehicles for a dealer with pagination",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        register("get_vehicle", "Get vehicle details by VIN",
                props(required("vin", "string", "Vehicle Identification Number")));

        register("decode_vin", "Decode a VIN to get manufacturer details",
                props(required("vin", "string", "Vehicle Identification Number")));

        // --- Customers ---
        register("list_customers", "List customers for a dealer",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        register("get_customer", "Get customer details by ID",
                props(required("customerId", "integer", "Customer ID")));

        register("find_customer",
                "Search for an existing customer by name. Use this BEFORE proposing create_customer "
                + "or any action that needs a customerId. More precise than list_customers (which is "
                + "paginated bulk listing). Searches via 'last name contains' match — for best results "
                + "pass the LAST name; the result set will be small enough to scan for the right person.",
                props(required("dealerCode", "string", "Dealer code, e.g. DLR01"),
                      required("lastName", "string", "Customer's last name (or partial match)"),
                      optional("firstName", "string", "Optional first name to narrow the match further")));

        // --- Deals ---
        register("list_deals", "List deals for a dealer",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        register("get_deal", "Get deal details by deal number",
                props(required("dealNumber", "string", "Deal number, e.g. DL01000001")));

        // --- Stock & Inventory ---
        register("get_stock_summary", "Get inventory stock summary (total on hand, in transit, sold, value)",
                props(required("dealerCode", "string", "Dealer code")));

        register("get_stock_positions", "Get stock positions with pagination",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        register("get_stock_aging", "Get aging report showing how long vehicles have been in stock",
                props(required("dealerCode", "string", "Dealer code")));

        register("get_stock_alerts", "Get low stock alerts for a dealer",
                props(required("dealerCode", "string", "Dealer code")));

        // --- Floor Plan ---
        register("get_floorplan_vehicles", "Get floor plan financed vehicles",
                props(required("dealerCode", "string", "Dealer code")));

        register("get_floorplan_exposure", "Get floor plan exposure/risk report",
                props(required("dealerCode", "string", "Dealer code")));

        // --- Finance ---
        register("list_finance_apps", "List finance applications for a dealer",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        // --- Registration & Warranty ---
        register("list_registrations", "List vehicle registrations for a dealer",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        register("get_warranty_by_vin", "Get warranty coverage details for a vehicle",
                props(required("vin", "string", "Vehicle Identification Number")));

        register("list_warranty_claims", "List warranty claims for a dealer",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        register("list_recalls", "List recall campaigns",
                props(optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        // --- Leads & CRM ---
        register("list_leads", "List customer leads for a dealer",
                props(required("dealerCode", "string", "Dealer code"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 10)")));

        // --- Batch & Reports ---
        register("get_batch_jobs", "Get batch job status and history", props());

        register("get_daily_sales_report", "Get daily sales report for a dealer",
                props(required("dealerCode", "string", "Dealer code")));

        register("get_commissions_report", "Get sales commissions report for a dealer",
                props(required("dealerCode", "string", "Dealer code")));

        // --- Safe Actions (POST) ---
        register("calculate_loan", "Calculate monthly loan payment for a vehicle purchase",
                props(required("principal", "number", "Loan principal amount (vehicle price minus down payment)"),
                      required("apr", "number", "Annual percentage rate (e.g. 5.9)"),
                      required("termMonths", "integer", "Loan term in months (e.g. 60)"),
                      optional("downPayment", "number", "Down payment in dollars (default 0)")));

        register("calculate_lease", "Calculate monthly lease payment",
                props(required("capitalizedCost", "number", "Capitalized cost (negotiated vehicle price)"),
                      optional("capCostReduction", "number", "Cap cost reduction / down payment (default 0)"),
                      optional("residualPct", "number", "Residual value percent (default 55.0)"),
                      optional("moneyFactor", "number", "Money factor (default 0.00125)"),
                      optional("termMonths", "integer", "Lease term in months (default 36)")));

        register("create_lead", "Create a new customer lead. REQUIRES an existing customerId — use list_customers first to find or confirm the customer; if no customer exists yet, decline and ask the user to create the customer first.",
                props(required("customerId", "integer", "ID of the EXISTING customer this lead is for. Resolve via list_customers before proposing."),
                      required("dealerCode", "string", "Dealer code"),
                      required("leadSource", "string", "Lead source: WALK_IN, PHONE, WEB, or REFERRAL"),
                      optional("interestModel", "string", "Vehicle model the customer is interested in"),
                      optional("interestYear", "integer", "Vehicle year the customer is interested in"),
                      optional("followUpDate", "string", "Follow-up date in YYYY-MM-DD format"),
                      optional("assignedSales", "string", "Salesperson user id; defaults to current caller")));

        // --- Incentives (read) ---
        register("list_incentives", "List available dealer incentive programs (rebates, low APR offers, lease specials, etc.). Filter by type or active flag.",
                props(optional("type", "string", "Filter by program type (e.g. REBATE, LOW_APR, LEASE_SPECIAL)"),
                      optional("active", "string", "Filter by active flag: true|false"),
                      optional("page", "integer", "Page number (default 0)"),
                      optional("size", "integer", "Page size (default 20)")));

        register("get_incentive", "Get details of a specific incentive program by program code/id.",
                props(required("programCode", "string", "Incentive program code or id, e.g. INC001")));

        // --- NHTSA federal data (live external API) ---
        register("nhtsa_recall_lookup",
                "Look up active federal recall campaigns affecting a specific VIN. "
                + "Hits NHTSA's recallsByVin API. Use this for VIN-specific recall questions; "
                + "use list_recalls for broad campaigns recorded in our local DB.",
                props(required("vin", "string", "17-character Vehicle Identification Number")));

        register("nhtsa_vin_decode",
                "Authoritative VIN decode via NHTSA's vPIC database. Returns make, model, "
                + "year, body class, manufacturer plant, engine info, etc. Use this when "
                + "decode_vin (our internal heuristic) is insufficient or you need canonical data.",
                props(required("vin", "string", "17-character Vehicle Identification Number")));

        register("run_credit_check", "Run a credit check for a customer",
                props(required("customerId", "integer", "Customer ID"),
                      required("dealerCode", "string", "Dealer code"),
                      required("bureau", "string", "Credit bureau: EXPERIAN, EQUIFAX, or TRANSUNION")));
    }

    public List<Map<String, Object>> getToolDefinitions() {
        return Collections.unmodifiableList(toolDefinitions);
    }

    // --- Builder helpers ---

    private void register(String name, String description, Map<String, Object> parameters) {
        toolDefinitions.add(Map.of(
                "type", "function",
                "function", Map.of(
                        "name", name,
                        "description", description,
                        "parameters", parameters
                )
        ));
    }

    private record PropDef(String name, String type, String description, boolean isRequired) {}

    private Map<String, Object> props(PropDef... defs) {
        Map<String, Object> properties = new LinkedHashMap<>();
        List<String> requiredList = new ArrayList<>();
        for (PropDef def : defs) {
            properties.put(def.name, Map.of("type", def.type, "description", def.description));
            if (def.isRequired) requiredList.add(def.name);
        }
        Map<String, Object> schema = new LinkedHashMap<>();
        schema.put("type", "object");
        schema.put("properties", properties);
        if (!requiredList.isEmpty()) schema.put("required", requiredList);
        return schema;
    }

    private PropDef required(String name, String type, String description) {
        return new PropDef(name, type, description, true);
    }

    private PropDef optional(String name, String type, String description) {
        return new PropDef(name, type, description, false);
    }
}
