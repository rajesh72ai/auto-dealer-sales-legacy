# Finance & Lending Domain -- Data Flows

## Overview

The Finance & Lending domain (F&I) handles everything that happens after a sales deal is approved: capturing finance applications (loan, lease, or cash), processing lender approvals/declines, calculating loan and lease payments, selecting F&I aftermarket products (extended warranty, GAP, etc.), generating closing documents, and running credit checks. This domain bridges Sales and the external lending world.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| FINAPP00 | Finance Application Capture          | FNAP            |
| FINAPV00 | Finance Approval / Decline Processing| FNAV            |
| FINCAL00 | Payment Calculator (Loan)            | FNCL            |
| FINCHK00 | Credit Check Interface               | FNCK            |
| FINDOC00 | Finance Document Generation          | FNDC            |
| FINLSE00 | Lease Calculator                     | FNLS            |
| FINPRD00 | F&I Product Selection                | FNPR            |

## Data Stores

| Table/Database              | Type | Key Fields                       | Used By                                |
|-----------------------------|------|----------------------------------|----------------------------------------|
| AUTOSALE.FINANCE_APP        | DB2  | FINANCE_ID (CHAR 12)             | FINAPP00, FINAPV00, FINDOC00, FINLSE00|
| AUTOSALE.SALES_DEAL         | DB2  | DEAL_NUMBER (CHAR 10)            | FINAPP00, FINAPV00, FINDOC00, FINPRD00, FINCHK00 |
| AUTOSALE.CREDIT_CHECK       | DB2  | CREDIT_ID (auto-gen)             | FINCHK00                               |
| AUTOSALE.CUSTOMER           | DB2  | CUSTOMER_ID                      | FINCHK00, FINDOC00                     |
| AUTOSALE.FINANCE_PRODUCT    | DB2  | DEAL_NUMBER, PRODUCT_SEQ         | FINPRD00, FINDOC00                     |
| AUTOSALE.LEASE_TERMS        | DB2  | FINANCE_ID                       | FINLSE00, FINDOC00                     |
| AUTOSALE.VEHICLE            | DB2  | VIN                              | FINDOC00                               |
| AUTOSALE.MODEL_MASTER       | DB2  | YEAR/MAKE/MODEL                  | FINDOC00                               |
| AUTOSALE.TRADE_IN           | DB2  | TRADE_ID                         | FINDOC00                               |
| AUTOSALE.DEALER             | DB2  | DEALER_CODE                      | FINDOC00                               |

## Data Flow Diagrams

### Finance Application Flow (FINAPP00)

```
[IMS Terminal]
    |
    | FNAP transaction (Deal Number, Finance Type, Lender, Terms)
    v
[FINAPP00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (validate STATUS = AP)
    |
    [Evaluate Finance Type:]
    |
    |-- L (Loan) -----+
    |                   |
    |   [Validate APR, TERM, DOWN_PAYMENT]
    |   [CALL COMLONL0] (calculate monthly payment)
    |     Payment = P * [r(1+r)^n] / [(1+r)^n - 1]
    |     where P = amount, r = monthly rate, n = months
    |                   |
    |-- S (Lease) -----+
    |                   |
    |   [Redirect to FINLSE00 for lease-specific calc]
    |                   |
    |-- C (Cash) ------+
    |                   |
    |   [Minimal processing - record type only]
    |
    v
    [CALL COMSEQL0] (generate FINANCE_ID)
    |
    [INSERT] --> [FINANCE_APP]
    |   STATUS = 'NW' (New)
    |   AMOUNT_REQUESTED = deal amount financed
    |
    [UPDATE] --> [SALES_DEAL]
    |   STATUS = 'FI' (In F&I)
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    |
    [ISRT confirmation] --> [Terminal]
```

### Finance Approval Flow (FINAPV00)

```
[IMS Terminal]
    |
    | FNAV transaction (Finance ID, Action, Approved Terms)
    v
[FINAPV00] --GU--> [IO PCB]
    |
    [SELECT] --> [FINANCE_APP] (get current application)
    |
    [Evaluate Action:]
    |
    |-- AP (Approve) --+
    |                   |
    |   [Record approved amount, APR, term]
    |   [CALL COMLONL0] (recalc payment with approved terms)
    |   [UPDATE FINANCE_APP]
    |     STATUS = 'AP', AMOUNT_APPROVED, APR_APPROVED
    |     DECISION_TS = current timestamp
    |   [UPDATE SALES_DEAL]
    |     AMOUNT_FINANCED = approved amount
    |
    |-- CD (Conditional) --+
    |                       |
    |   [Record stipulations]
    |   [UPDATE FINANCE_APP]
    |     STATUS = 'CD', STIPULATIONS = input text
    |
    |-- DN (Decline) ------+
    |                       |
    |   [UPDATE FINANCE_APP]
    |     STATUS = 'DN'
    |   [Allow resubmit to different lender]
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT decision display] --> [Terminal]
```

### Payment Calculator Flow (FINCAL00)

```
[IMS Terminal]
    |
    | FNCL transaction (Principal, APR, Term, Down Payment)
    v
[FINCAL00] --GU--> [IO PCB]
    |
    [NO DB2 UPDATES - Pure calculation tool]
    |
    [Validate numeric inputs]
    |
    [CALL COMLONL0] (loan calculation)
    |
    [Calculate for input terms:]
    |  - Monthly payment
    |  - Total of payments
    |  - Total interest
    |  - First year amortization schedule
    |
    [Side-by-side comparison:]
    |  36 months | 48 months | 60 months | 72 months
    |  (same principal + APR, vary term)
    |
    [ISRT calculator display] --> [Terminal]
```

### Credit Check Flow (FINCHK00)

```
[IMS Terminal]
    |
    | FNCK transaction (Customer ID or Deal Number)
    v
[FINCHK00] --GU--> [IO PCB]
    |
    [If Deal Number provided:]
    |   [SELECT] --> [SALES_DEAL] (get CUSTOMER_ID)
    |
    [SELECT] --> [CUSTOMER] (get income, debt info)
    |
    [SELECT] --> [CREDIT_CHECK]
    |   (check for existing non-expired report)
    |
    +--VALID REPORT EXISTS----> [Display existing report]
    |
    +--NO VALID REPORT-------> [Initiate new check]
                                |
                         [Simulate bureau response:]
                         |  Score based on income + debt
                         |  Tier: A(750+), B(700-749),
                         |        C(650-699), D(600-649), E(<600)
                         |  DTI = monthly_debt / monthly_income
                                |
                         [INSERT/UPDATE] --> [CREDIT_CHECK]
                         |  STATUS = 'RC' (Received)
                         |  EXPIRY = +30 days
                                |
                         [Calculate:]
                         |  Max finance = income * multiplier
                         |  Monthly budget = income/12 * 0.15
                                |
                         [CALL COMLGEL0] --> [AUDIT_LOG]
                         [ISRT results] --> [Terminal]
```

### Lease Calculator Flow (FINLSE00)

```
[IMS Terminal]
    |
    | FNLS transaction (Cap Cost, Residual%, Money Factor, Term, Tax)
    v
[FINLSE00] --GU--> [IO PCB]
    |
    [CALL COMLESL0] (lease calculation)
    |
    [Calculate:]
    |  Residual Amount = MSRP * Residual%
    |  Adj Cap Cost = Cap Cost - Cap Cost Reduction
    |  Monthly Depreciation = (Adj Cap - Residual) / Term
    |  Monthly Finance = (Adj Cap + Residual) * Money Factor
    |  Monthly Tax = (Depreciation + Finance) * Tax Rate
    |  Total Monthly = Depreciation + Finance + Tax
    |  Drive-off = 1st month + Security + Acq Fee + Cap Reduction
    |
    [If Deal Number provided:]
    |   [SELECT] --> [FINANCE_APP] (get FINANCE_ID)
    |   [INSERT] --> [LEASE_TERMS]
    |     (all calculated fields stored)
    |
    [ISRT lease display] --> [Terminal]
```

### F&I Product Selection Flow (FINPRD00)

```
[IMS Terminal]
    |
    | FNPR transaction (Deal Number, Product Selections)
    v
[FINPRD00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (validate deal)
    |
    [Display product menu:]
    |  EXW = Extended Warranty
    |  GAP = GAP Insurance
    |  PPT = Paint Protection
    |  FBR = Fabric Protection
    |  THF = Theft Deterrent
    |  MNT = Maintenance Plan
    |  TIR = Tire & Wheel
    |  DNT = Dent Protection
    |  KEY = Key Replacement
    |  LOJ = LoJack
    |
    [For each selected product:]
    |   [INSERT] --> [FINANCE_PRODUCT]
    |     (type, name, term, selling price, dealer cost, gross)
    |
    [Calculate total F&I gross]
    |   BACK_GROSS = SUM(GROSS_PROFIT) for all products
    |
    [UPDATE] --> [SALES_DEAL]
    |   BACK_GROSS = calculated
    |   TOTAL_GROSS = FRONT_GROSS + BACK_GROSS
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT product summary] --> [Terminal]
```

### Document Generation Flow (FINDOC00)

```
[IMS Terminal]
    |
    | FNDC transaction (Deal Number)
    v
[FINDOC00] --GU--> [IO PCB]
    |
    [Gather all deal data:]
    |---SELECT---> [SALES_DEAL]
    |---SELECT---> [CUSTOMER]       (buyer info)
    |---SELECT---> [VEHICLE]        (vehicle description)
    |---SELECT---> [MODEL_MASTER]   (make/model names)
    |---SELECT---> [FINANCE_APP]    (finance terms)
    |---SELECT---> [TRADE_IN]       (trade info if applicable)
    |---SELECT---> [LEASE_TERMS]    (if lease)
    |---CURSOR---> [FINANCE_PRODUCT](all F&I products)
    |---SELECT---> [DEALER]         (seller info)
    |
    [Format document based on finance type:]
    |
    |-- Loan ---> Retail Installment Contract
    |             (CALL COMLONL0 for payment verification)
    |
    |-- Lease --> Lease Agreement
    |             (CALL COMLESL0 for payment verification)
    |
    |-- Cash ---> Cash Receipt
    |
    [Multi-segment IMS output for print]
    [ISRT document segments] --> [Terminal/Printer]
```

## Field-Level Data Mapping

| Source Field (COBOL)       | Table.Column                   | Format             | Validation Rules                          |
|---------------------------|--------------------------------|--------------------|--------------------------------------------|
| WS-AI-DEAL-NUMBER         | FINANCE_APP.DEAL_NUMBER        | X(10)              | Must exist, STATUS=AP                      |
| WS-AI-FINANCE-TYPE        | FINANCE_APP.FINANCE_TYPE       | X(01)              | L=Loan, S=Lease, C=Cash                   |
| WS-AI-LENDER-CODE         | FINANCE_APP.LENDER_CODE        | X(05)              | Required for L/S types                     |
| WS-AI-APR                 | FINANCE_APP.APR_REQUESTED      | X(06)->DEC(5,3)    | 0-25%                                      |
| WS-AI-TERM                | FINANCE_APP.TERM_MONTHS        | X(03)->SMALLINT    | 12-84 months                               |
| WS-AI-DOWN-PAYMENT        | FINANCE_APP.DOWN_PAYMENT       | X(11)->DEC(11,2)   | >= 0                                       |
| WS-AI-AMOUNT-APPROVED     | FINANCE_APP.AMOUNT_APPROVED    | DEC(11,2)          | Set by FINAPV00                            |
| WS-AI-APR-APPROVED        | FINANCE_APP.APR_APPROVED       | DEC(5,3)           | Set by FINAPV00                            |
| WS-LI-RESIDUAL-PCT        | LEASE_TERMS.RESIDUAL_PCT       | DEC(5,2)           | 30-70%                                     |
| WS-LI-MONEY-FACTOR        | LEASE_TERMS.MONEY_FACTOR       | DEC(7,6)           | Equivalent APR / 2400                      |
| WS-PI-SELECTIONS           | FINANCE_PRODUCT (multi-row)   | X(30)              | Product codes from catalog                 |

## Error Paths

- **FINAPP00**: Deal not in AP status rejected. Invalid finance type rejected. COMLONL0 calculation failure (negative amount, zero term) returns error. COMSEQL0 failure prevents ID generation.
- **FINAPV00**: Finance app not found or not in submittable status rejected. Approved amount exceeding requested by more than 10% flagged as warning.
- **FINCAL00**: Non-numeric inputs rejected. Zero principal or zero term returns error. No DB2 operations so no DB2 errors possible.
- **FINCHK00**: Customer not found returns error. Deal not found (if searching by deal) returns error.
- **FINDOC00**: Missing any required data component (customer, vehicle, finance) returns specific error indicating which data is missing.
- **FINLSE00**: Residual percentage outside 30-70% returns warning. Money factor sanity check.
- **FINPRD00**: Deal not found or in wrong status rejected. Invalid product code ignored with warning.

## Cross-Domain Dependencies

| Dependency Direction       | Related Domain        | Data Exchanged                                                |
|---------------------------|-----------------------|---------------------------------------------------------------|
| Finance <-- Sales         | SALES_DEAL must be AP status; deal pricing drives finance amount |
| Finance <-- Customer      | CUSTOMER data for applications and documents                  |
| Finance --> Sales          | FINAPV00 updates SALES_DEAL.AMOUNT_FINANCED; FINAPP00 sets status FI |
| Finance <-- Admin          | DEALER info for documents; SYSTEM_CONFIG for sequences        |
| Finance <-- Vehicle        | VEHICLE and MODEL_MASTER for document generation              |
| Finance --> Customer       | FINCHK00 creates/updates CREDIT_CHECK records                |
| Finance <-- Customer       | CREDIT_CHECK data read for pre-existing reports               |
