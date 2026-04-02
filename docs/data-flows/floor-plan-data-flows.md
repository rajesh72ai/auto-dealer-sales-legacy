# Floor Plan Management Domain -- Data Flows

## Overview

The Floor Plan domain manages the dealer's vehicle financing with wholesale lenders. When a dealer receives a vehicle from the manufacturer, the floor plan lender finances the vehicle's invoice cost. The dealer pays daily interest on the floored balance until the vehicle is sold and the floor plan is paid off. This domain tracks vehicle additions to floor plan, interest accrual, payoff processing, inquiry/filtering, and exposure reporting.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| FPLADD00 | Floor Plan Vehicle Add               | FPLA            |
| FPLINQ00 | Floor Plan Inquiry                   | FPLI            |
| FPLINT00 | Floor Plan Interest Calculation      | FPLN            |
| FPLPAY00 | Floor Plan Payoff                    | FPLP            |
| FPLRPT00 | Floor Plan Exposure Report           | FPLR            |

## Data Stores

| Table/Database                  | Type | Key Fields                    | Used By                              |
|---------------------------------|------|-------------------------------|--------------------------------------|
| AUTOSALE.FLOOR_PLAN_VEHICLE     | DB2  | FLOOR_PLAN_ID (auto-gen)      | All FPL programs                     |
| AUTOSALE.FLOOR_PLAN_INTEREST    | DB2  | INTEREST_ID (auto-gen)        | FPLINT00                             |
| AUTOSALE.VEHICLE                | DB2  | VIN (CHAR 17)                 | FPLADD00, FPLINQ00, FPLRPT00        |
| AUTOSALE.DEALER                 | DB2  | DEALER_CODE (CHAR 5)          | FPLADD00                             |
| AUTOSALE.LENDER                 | DB2  | LENDER_ID (CHAR 5)            | FPLADD00, FPLRPT00                   |
| AUTOSALE.MODEL_MASTER           | DB2  | YEAR/MAKE/MODEL               | FPLINQ00                             |

## Data Flow Diagrams

### Floor Plan Vehicle Add (FPLADD00)

```
[IMS Terminal]
    |
    | FPLA transaction (VIN, Lender ID, Dealer Code)
    v
[FPLADD00] --GU--> [IO PCB]
    |
    [CALL COMVALD0] (validate VIN)
    |
    [SELECT] --> [VEHICLE] (get invoice price, verify exists)
    [SELECT] --> [DEALER]  (get dealer info, FP lender association)
    [SELECT] --> [LENDER]  (get lender terms: rate, spread,
    |                        curtailment days, free floor days)
    |
    [Calculate:]
    |  INVOICE_AMOUNT = vehicle invoice price
    |  CURRENT_BALANCE = INVOICE_AMOUNT
    |  FLOOR_DATE = current date
    |  CURTAILMENT_DATE = FLOOR_DATE + curtailment_days
    |  RATE = BASE_RATE + SPREAD
    |
    [INSERT] --> [FLOOR_PLAN_VEHICLE]
    |   FP_STATUS = 'AC' (Active)
    |   DAYS_ON_FLOOR = 0
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT confirmation] --> [Terminal]
```

### Interest Calculation Flow (FPLINT00)

```
[IMS Terminal]
    |
    | FPLN transaction (Mode: S=Single/B=Batch, VIN, Dealer)
    v
[FPLINT00] --GU--> [IO PCB]
    |
    |-- MODE=S (Single VIN) ----+
    |                            |
    |   [SELECT] --> [FLOOR_PLAN_VEHICLE] (by VIN)
    |
    |-- MODE=B (Batch/All) -----+
    |                            |
    |   [CURSOR] --> [FLOOR_PLAN_VEHICLE]
    |     (WHERE FP_STATUS = 'AC' AND DEALER_CODE = input)
    |
    [For each active floor plan record:]
    |
    |   [CALL COMINTL0] (interest calculation)
    |     DAILY_INTEREST = PRINCIPAL_BAL * (RATE / 365)
    |     CUMULATIVE = previous + DAILY_INTEREST
    |
    |   [INSERT] --> [FLOOR_PLAN_INTEREST]
    |     (CALC_DATE, PRINCIPAL_BAL, RATE, DAILY_INTEREST, CUMULATIVE)
    |
    |   [UPDATE] --> [FLOOR_PLAN_VEHICLE]
    |     INTEREST_ACCRUED = CUMULATIVE
    |     LAST_INTEREST_DT = current date
    |     DAYS_ON_FLOOR + 1
    |
    |   [Check curtailment proximity:]
    |     IF DAYS_ON_FLOOR > (CURTAILMENT_DAYS - 15)
    |       --> Flag "CURTAILMENT APPROACHING"
    |
    [ISRT summary/details] --> [Terminal]
```

### Floor Plan Payoff Flow (FPLPAY00)

```
[IMS Terminal]
    |
    | FPLP transaction (VIN)
    v
[FPLPAY00] --GU--> [IO PCB]
    |
    [SELECT] --> [FLOOR_PLAN_VEHICLE] (by VIN, STATUS = AC)
    |
    [CALL COMINTL0] (calculate final interest to payoff date)
    |   FINAL_INTEREST = balance * rate * days_since_last_calc / 365
    |   PAYOFF_AMOUNT = CURRENT_BALANCE + FINAL_INTEREST
    |
    [UPDATE] --> [FLOOR_PLAN_VEHICLE]
    |   FP_STATUS = 'PD' (Paid Off)
    |   PAYOFF_DATE = current date
    |   INTEREST_ACCRUED = INTEREST_ACCRUED + FINAL_INTEREST
    |   CURRENT_BALANCE = 0
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT payoff confirmation] --> [Terminal]
    |
    [Shows: VIN, Floor Date, Days, Invoice, Interest, Payoff Total]
```

### Floor Plan Inquiry Flow (FPLINQ00)

```
[IMS Terminal]
    |
    | FPLI transaction (Dealer, optional: VIN/Status/Lender filter)
    v
[FPLINQ00] --GU--> [IO PCB]
    |
    [CURSOR] --> [FLOOR_PLAN_VEHICLE]
                    JOIN [VEHICLE]
                    JOIN [MODEL_MASTER]
    |   (WHERE DEALER_CODE = input
    |    AND optional VIN, STATUS, LENDER filters)
    |
    [For each row:]
    |   - VIN
    |   - Model description (Year Make Model)
    |   - Floor date
    |   - Days on floor
    |   - Current balance
    |   - Interest accrued
    |   - Status (AC/CT/PD/WO)
    |
    [CALL COMINTL0] (real-time interest calc for display)
    |
    [Calculate totals:]
    |   - Total balance
    |   - Total interest
    |
    [Supports PF7/PF8 paging]
    |
    [ISRT list display] --> [Terminal]
```

### Floor Plan Exposure Report (FPLRPT00)

```
[IMS Terminal]
    |
    | FPLR transaction (Dealer Code)
    v
[FPLRPT00] --GU--> [IO PCB]
    |
    [CURSOR] --> [FLOOR_PLAN_VEHICLE]
                    JOIN [VEHICLE]
                    JOIN [LENDER]
    |   (WHERE DEALER_CODE = input AND FP_STATUS = 'AC')
    |
    [Aggregate by lender (up to 8 lenders):]
    |   - Lender name
    |   - Vehicle count
    |   - Total balance
    |   - Total interest
    |
    [Aggregate by age bucket:]
    |   - 0-30 days:  count, balance
    |   - 31-60 days: count, balance
    |   - 61-90 days: count, balance
    |   - 90+ days:   count, balance
    |
    [Calculate:]
    |   - Weighted average interest rate
    |   - Average days on floor
    |   - Grand total balance
    |   - Grand total interest
    |
    [ISRT report display] --> [Terminal]
```

## Field-Level Data Mapping

| Source Field (COBOL)       | Table.Column                        | Format            | Validation Rules                     |
|---------------------------|-------------------------------------|--------------------|-----------------------------------------|
| WS-IN-VIN                 | FLOOR_PLAN_VEHICLE.VIN              | X(17)              | Must exist in VEHICLE, validated via COMVALD0 |
| WS-IN-LENDER-ID           | FLOOR_PLAN_VEHICLE.LENDER_ID        | X(05)              | Must exist in LENDER table               |
| WS-IN-DEALER-CODE         | FLOOR_PLAN_VEHICLE.DEALER_CODE      | X(05)              | Must exist in DEALER table               |
| (calculated)              | FLOOR_PLAN_VEHICLE.INVOICE_AMOUNT   | DEC(11,2)          | From VEHICLE invoice lookup              |
| (calculated)              | FLOOR_PLAN_VEHICLE.CURTAILMENT_DATE | DATE               | FLOOR_DATE + lender curtailment days     |
| (calculated)              | FLOOR_PLAN_INTEREST.DAILY_INTEREST  | DEC(9,4)           | balance * rate / 365                     |
| (calculated)              | FLOOR_PLAN_INTEREST.CUMULATIVE_INT  | DEC(9,2)           | Running sum of daily interest            |
| WS-IN-STATUS-FILTER       | (query parameter)                   | X(02)              | AC/CT/PD/WO                              |

## Error Paths

- **FPLADD00**: VIN not found or fails COMVALD0 returns error. Lender not found returns error. Vehicle already on floor plan (duplicate VIN check) returns error.
- **FPLINT00**: No active floor plan records for dealer (batch mode) returns "NO ACTIVE FLOOR PLANS". Single VIN not found returns error.
- **FPLPAY00**: VIN not on active floor plan returns error. Already paid off (STATUS=PD) returns "ALREADY PAID OFF".
- **FPLINQ00**: No records matching filters returns "NO FLOOR PLAN VEHICLES FOUND". Page beyond bounds handled gracefully.
- **FPLRPT00**: No active floor plans for dealer returns "NO ACTIVE FLOOR PLANS FOR DEALER".

## Cross-Domain Dependencies

| Dependency Direction        | Related Domain       | Data Exchanged                                          |
|----------------------------|----------------------|---------------------------------------------------------|
| Floor Plan <-- Vehicle     | VEHICLE record provides invoice price and VIN validation |
| Floor Plan <-- Admin       | DEALER and LENDER records for setup; rates and terms     |
| Floor Plan <-- Sales       | SALCAN00 reverses floor plan payoff on deal cancellation |
| Floor Plan --> Sales       | FPLPAY00 triggered when vehicle sold (SALCMP00 flow)    |
| Floor Plan --> Stock       | Floor plan aging data feeds into stock aging analysis    |
