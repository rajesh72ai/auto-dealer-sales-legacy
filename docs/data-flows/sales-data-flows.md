# Sales Process Domain -- Data Flows

## Overview

The Sales Process domain manages the entire deal lifecycle from initial quote/worksheet through negotiation, trade-in evaluation, incentive application, validation, management approval, sale completion, and cancellation/unwind. It is the central transactional domain of AUTOSALES, coordinating data from Customer, Vehicle, Finance, Stock, and Administration domains.

## Programs in This Domain

| Program  | Description                        | Transaction Code |
|----------|------------------------------------|-----------------|
| SALQOT00 | Deal Worksheet / Quote Generation  | SALQ            |
| SALNEG00 | Price Negotiation                  | SALN            |
| SALTRD00 | Trade-In Vehicle Evaluation        | SALT            |
| SALINC00 | Incentive / Rebate Application     | SALI            |
| SALVAL00 | Deal Validation                    | SALV            |
| SALAPV00 | Sales Approval Workflow            | SALA            |
| SALCMP00 | Sale Completion / Closing          | SALC            |
| SALCAN00 | Sale Cancellation / Unwind         | SALX            |

## Data Stores

| Table/Database                | Type | Key Fields                        | Used By                                    |
|-------------------------------|------|-----------------------------------|--------------------------------------------|
| AUTOSALE.SALES_DEAL           | DB2  | DEAL_NUMBER (CHAR 10)             | All SAL programs                           |
| AUTOSALE.DEAL_LINE_ITEM       | DB2  | DEAL_NUMBER, LINE_SEQ             | SALQOT00                                   |
| AUTOSALE.TRADE_IN             | DB2  | TRADE_ID (auto-gen)               | SALTRD00, SALCMP00, SALCAN00               |
| AUTOSALE.INCENTIVE_APPLIED    | DB2  | DEAL_NUMBER, INCENTIVE_ID         | SALINC00, SALVAL00, SALCAN00               |
| AUTOSALE.INCENTIVE_PROGRAM    | DB2  | INCENTIVE_ID                      | SALINC00, SALVAL00, SALCAN00               |
| AUTOSALE.SALES_APPROVAL       | DB2  | APPROVAL_ID (auto-gen)            | SALAPV00                                   |
| AUTOSALE.CUSTOMER             | DB2  | CUSTOMER_ID                       | SALQOT00, SALNEG00, SALINC00, SALVAL00    |
| AUTOSALE.VEHICLE              | DB2  | VIN                               | SALQOT00, SALINC00, SALVAL00, SALCMP00, SALCAN00 |
| AUTOSALE.VEHICLE_OPTION       | DB2  | VIN, OPTION_CODE                  | SALQOT00                                   |
| AUTOSALE.PRICE_MASTER         | DB2  | YEAR/MAKE/MODEL/EFF_DATE          | SALQOT00 (via COMPRCL0), SALTRD00          |
| AUTOSALE.TAX_RATE             | DB2  | STATE/COUNTY/CITY/EFF_DATE        | SALQOT00, SALNEG00 (via COMTAXL0)          |
| AUTOSALE.SYSTEM_USER          | DB2  | USER_ID                           | SALQOT00, SALNEG00, SALAPV00, SALVAL00    |
| AUTOSALE.SYSTEM_CONFIG        | DB2  | CONFIG_KEY                        | SALVAL00 (min margin), SALQOT00 (sequences)|
| AUTOSALE.STOCK_POSITION       | DB2  | DEALER/YEAR/MAKE/MODEL            | SALCMP00 (via COMSTCK0), SALCAN00          |
| AUTOSALE.FINANCE_APP          | DB2  | FINANCE_ID                        | SALCMP00                                   |
| AUTOSALE.CREDIT_CHECK         | DB2  | CREDIT_ID                         | SALVAL00                                   |
| AUTOSALE.FLOOR_PLAN_VEHICLE   | DB2  | FLOOR_PLAN_ID                     | SALCAN00                                   |

## Data Flow Diagrams

### Complete Deal Lifecycle

```
[Customer]   [Vehicle]   [Salesperson]
    |            |             |
    +------+-----+------+------+
           |            |
           v            v
     [SALQOT00] -----> [SALES_DEAL] STATUS=WS (Worksheet)
           |                 |
           |           [DEAL_LINE_ITEM] (vehicle, options, fees, tax)
           |
           v
     [SALNEG00] -----> [SALES_DEAL] STATUS=NE (Negotiating)
           |                 |
           |           (counter offers, discount adjustments)
           |
           v
     [SALTRD00] -----> [TRADE_IN] + update SALES_DEAL net trade
           |
           v
     [SALINC00] -----> [INCENTIVE_APPLIED] + update SALES_DEAL rebates
           |
           v
     [SALVAL00] -----> [SALES_DEAL] STATUS=PA (Pending Approval)
           |                 |
           |           (comprehensive validation checklist)
           |
           v
     [SALAPV00] -----> [SALES_APPROVAL] + SALES_DEAL STATUS=AP
           |                               or back to NE if rejected
           |
           v
     [Finance Domain] --> STATUS=FI (In F&I)
           |
           v
     [SALCMP00] -----> [SALES_DEAL] STATUS=DL (Delivered)
           |                 |
           |           [VEHICLE] STATUS=SD (Sold)
           |           [STOCK_POSITION] decremented
           |
           v
     [SALCAN00] -----> [SALES_DEAL] STATUS=CA/UW
      (if needed)            |
                       (reverses all: vehicle, stock, incentives, floor plan)
```

### Quote / Worksheet Generation (SALQOT00)

```
[IMS Terminal]
    |
    | SALQ transaction (Customer ID, VIN, Salesperson, Deal Type)
    v
[SALQOT00] --GU--> [IO PCB]
    |
    |---SELECT---> [CUSTOMER]      (validate exists)
    |---SELECT---> [VEHICLE]       (validate exists, status=AV)
    |---SELECT---> [SYSTEM_USER]   (validate salesperson)
    |---CALL-----> [COMPRCL0] ---> [PRICE_MASTER] (get MSRP, invoice)
    |---CURSOR---> [VEHICLE_OPTION] (sum option prices)
    |---CALL-----> [COMTAXL0] ---> [TAX_RATE] (state/county/city tax)
    |
    v
[Build Deal Worksheet]
    |  SUBTOTAL = VEHICLE_PRICE + OPTIONS + DEST_FEE
    |  TAX = SUBTOTAL * combined_rate
    |  TOTAL = SUBTOTAL + TAX + DOC_FEE + TITLE + REG
    |  FRONT_GROSS = VEHICLE_PRICE - INVOICE
    |
    |---CALL-----> [COMSEQL0] (generate DEAL_NUMBER from SYSTEM_CONFIG)
    |---INSERT---> [SALES_DEAL] (STATUS=WS)
    |---INSERT---> [DEAL_LINE_ITEM] (multiple: VH, OP, FE, TX)
    |---CALL-----> [COMLGEL0] --> [AUDIT_LOG]
    |
    [ISRT worksheet display] --> [Terminal]
```

### Negotiation Flow (SALNEG00)

```
[IMS Terminal]
    |
    | SALN transaction (Deal Number, Counter Offer / Discount)
    v
[SALNEG00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (get current deal)
    [SELECT] --> [SYSTEM_USER] (check user type for visibility)
    |
    |  Manager sees: MSRP, Invoice, Holdback, Gross, Margin%
    |  Salesperson sees: MSRP, Current Offer
    |
    [Apply counter offer or discount]
    |  - By amount: new_price = current - discount
    |  - By percent: new_price = MSRP * (1 - pct)
    |
    [Recalculate all deal financials]
    |  - Tax recalculated on new subtotal (via COMTAXL0)
    |  - FRONT_GROSS = new_price - INVOICE
    |  - TOTAL recalculated
    |
    [UPDATE] --> [SALES_DEAL] (STATUS=NE, new pricing)
    [CALL] --> [COMLGEL0] --> [AUDIT_LOG]
    |
    [ISRT negotiation display] --> [Terminal]
```

### Trade-In Evaluation Flow (SALTRD00)

```
[IMS Terminal]
    |
    | SALT transaction
    v
[SALTRD00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (validate deal exists)
    |
    [If VIN provided:]
    |   [CALL COMVALD0] (validate trade VIN)
    |   [CALL COMVINL0] (decode VIN for year/make/model)
    |
    [Calculate ACV based on condition:]
    |   E = 100% of base value
    |   G = 85%
    |   F = 70%
    |   P = 55%
    |   Base value from [PRICE_MASTER]
    |
    [INSERT] --> [TRADE_IN]
    |   (VIN, year, make, model, odometer, condition,
    |    ACV, allowance, over-allow, payoff info)
    |
    [UPDATE] --> [SALES_DEAL]
    |   NET_TRADE = ALLOWANCE - PAYOFF
    |   AMOUNT_FINANCED recalculated
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT trade display] --> [Terminal]
```

### Sale Completion Flow (SALCMP00)

```
[IMS Terminal]
    |
    | SALC transaction (Deal Number + checklist flags)
    v
[SALCMP00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (must be AP or FI status)
    |
    [Validate Checklist:]
    |  - Trade title received (if trade exists)
    |  - Insurance verified
    |  - Finance approved (if not cash)
    |  - Down payment received
    |
    [All checks pass:]
    |
    |---UPDATE---> [SALES_DEAL]
    |                STATUS = 'DL' (Delivered)
    |                DELIVERY_DATE = current date
    |
    |---UPDATE---> [VEHICLE]
    |                VEHICLE_STATUS = 'SD' (Sold)
    |
    |---CALL-----> [COMSTCK0] --> [STOCK_POSITION]
    |                ON_HAND_COUNT - 1
    |                SOLD_MTD + 1
    |                SOLD_YTD + 1
    |
    |---CALL-----> [COMLGEL0] --> [AUDIT_LOG]
    |
    |   [Triggers downstream:]
    |   --> Warranty Registration (WRCWAR00)
    |   --> Registration Assembly (REGGEN00)
    |
    [ISRT completion display] --> [Terminal]
```

### Sale Cancellation / Unwind Flow (SALCAN00)

```
[IMS Terminal]
    |
    | SALX transaction (Deal Number + Reason)
    v
[SALCAN00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (must not be CA/UW already)
    |
    [Reversal Steps:]
    |
    |---If VEHICLE_STATUS = SD:
    |     UPDATE [VEHICLE] STATUS = 'AV'
    |     CALL [COMSTCK0] RECV --> [STOCK_POSITION] (reverse sold)
    |
    |---If INCENTIVE_APPLIED records exist:
    |     SELECT/DELETE --> [INCENTIVE_APPLIED]
    |     UPDATE [INCENTIVE_PROGRAM] UNITS_USED - applied count
    |
    |---If FLOOR_PLAN was paid off:
    |     UPDATE [FLOOR_PLAN_VEHICLE] reverse payoff
    |
    |---UPDATE---> [SALES_DEAL]
    |                STATUS = 'CA' (Cancelled) or 'UW' (Unwound)
    |
    |---CALL-----> [COMLGEL0] --> [AUDIT_LOG]
    |   (comprehensive audit for each reversal step)
    |
    [ISRT cancellation confirmation] --> [Terminal]
```

## Field-Level Data Mapping

| Source Field (COBOL)       | Table.Column                    | Format              | Validation Rules                          |
|---------------------------|---------------------------------|---------------------|-------------------------------------------|
| WS-QI-CUST-ID            | SALES_DEAL.CUSTOMER_ID          | X(09) -> INT        | Must exist in CUSTOMER                    |
| WS-QI-VIN                | SALES_DEAL.VIN                  | X(17)               | Must exist, STATUS=AV                     |
| WS-QI-SALES-ID           | SALES_DEAL.SALESPERSON_ID       | X(08)               | Must exist in SYSTEM_USER                 |
| WS-QI-DEAL-TYPE          | SALES_DEAL.DEAL_TYPE            | X(01)               | R=Retail, L=Lease, F=Fleet, W=Wholesale   |
| WS-NI-COUNTER-OFFER      | SALES_DEAL.VEHICLE_PRICE        | X(12) -> DEC(11,2)  | Must be > 0                               |
| WS-NI-DISCOUNT-AMT       | SALES_DEAL.DISCOUNT_AMT         | X(12) -> DEC(9,2)   | Cannot exceed vehicle price               |
| WS-TI-TRADE-VIN          | TRADE_IN.VIN                    | X(17)               | Optional; validated if provided           |
| WS-TI-CONDITION          | TRADE_IN.CONDITION_CODE         | X(01)               | E/G/F/P                                   |
| WS-TI-PAYOFF-AMT         | TRADE_IN.PAYOFF_AMT             | X(11) -> DEC(11,2)  | >= 0                                       |
| WS-AI-ACTION (SALAPV00)  | SALES_APPROVAL.APPROVAL_STATUS  | X(02)               | AP=Approve, RJ=Reject                    |
| WS-AI-APPROVER-ID        | SALES_APPROVAL.APPROVER_ID      | X(08)               | Must be M (Manager) or above              |

## Error Paths

- **SALQOT00**: Customer not found, vehicle not available (wrong status), salesperson invalid, or vehicle already in a deal all return specific errors. COMSEQL0 failure prevents deal creation.
- **SALNEG00**: Deal not found or not in WS/NE status rejects negotiation. Discount exceeding vehicle price rejected.
- **SALTRD00**: Invalid condition code rejected. Trade VIN failing COMVALD0 returns decode error.
- **SALINC00**: Non-stackable incentives cannot combine. Expired incentives excluded. Units exhausted (UNITS_USED >= MAX_UNITS) excluded.
- **SALVAL00**: Returns list of all validation failures: missing credit check, vehicle no longer available, pricing below minimum margin (from SYSTEM_CONFIG), tax not calculated, trade payoff unverified, incentive expired since application.
- **SALAPV00**: Non-manager user rejected. Loser deals (FRONT_GROSS < 0) require GM-level approval. Rejected deals return to NE status.
- **SALCMP00**: Incomplete checklist items listed individually. Deal must be in AP or FI status.
- **SALCAN00**: Already cancelled/unwound deals rejected. Each reversal step individually audited; partial reversal on DB error results in deal status remaining unchanged.

## Cross-Domain Dependencies

| Dependency Direction       | Related Domain         | Data Exchanged                                                |
|---------------------------|------------------------|---------------------------------------------------------------|
| Sales <-- Customer        | CUSTOMER record required for deal creation                    |
| Sales <-- Vehicle         | VEHICLE must be AV status; VEHICLE_OPTION for pricing         |
| Sales <-- Admin           | PRICE_MASTER, TAX_RATE, INCENTIVE_PROGRAM, SYSTEM_CONFIG, SYSTEM_USER |
| Sales --> Vehicle          | SALCMP00 updates VEHICLE.STATUS to SD; SALCAN00 reverses     |
| Sales --> Stock            | SALCMP00/SALCAN00 update STOCK_POSITION via COMSTCK0         |
| Sales --> Finance          | Approved deal flows to FINAPP00; SALCMP00 reads FINANCE_APP  |
| Sales --> Floor Plan       | SALCAN00 reverses FLOOR_PLAN_VEHICLE payoff                  |
| Sales --> Warranty         | SALCMP00 triggers WRCWAR00 warranty registration             |
| Sales --> Registration     | SALCMP00 triggers REGGEN00 registration assembly             |
