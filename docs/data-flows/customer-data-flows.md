# Customer Management Domain -- Data Flows

## Overview

The Customer Management domain handles the complete customer lifecycle within AUTOSALES: creating customer profiles, searching and browsing customers, updating records, tracking sales leads through their funnel, running credit pre-qualification checks, and viewing purchase history. This domain is a prerequisite for all sales activity -- a customer record must exist before a deal can be created.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| CUSADD00 | Add/Create Customer Profile          | CSAD            |
| CUSCRED0 | Credit Pre-Qualification             | CSCR            |
| CUSHIS00 | Purchase History Display             | CSHI            |
| CUSINQ00 | Customer Search / Inquiry            | CSIQ            |
| CUSLEAD0 | Lead Tracking & Management           | CSLD            |
| CUSLST00 | Customer Listing / Browse            | CSLS            |
| CUSUPD00 | Update Customer Profile              | CSUP            |

## Data Stores

| Table/Database            | Type | Key Fields                  | Used By                               |
|---------------------------|------|-----------------------------|---------------------------------------|
| AUTOSALE.CUSTOMER         | DB2  | CUSTOMER_ID (auto-gen INT)  | CUSADD00, CUSINQ00, CUSLST00, CUSUPD00, CUSHIS00, CUSCRED0, CUSLEAD0 |
| AUTOSALE.CUSTOMER_LEAD    | DB2  | LEAD_ID (auto-gen INT)      | CUSLEAD0                              |
| AUTOSALE.CREDIT_CHECK     | DB2  | CREDIT_ID (auto-gen INT)    | CUSCRED0                              |
| AUTOSALE.SYSTEM_USER      | DB2  | USER_ID (CHAR 8)            | CUSADD00 (round-robin assignment)     |
| AUTOSALE.SALES_DEAL       | DB2  | DEAL_NUMBER (CHAR 10)       | CUSHIS00 (read for history)           |
| AUTOSALE.VEHICLE          | DB2  | VIN (CHAR 17)               | CUSHIS00 (join for model info)        |
| AUTOSALE.TRADE_IN         | DB2  | TRADE_ID (auto-gen INT)     | CUSHIS00 (left join)                  |
| AUTOSALE.AUDIT_LOG        | DB2  | AUDIT_ID (auto-gen INT)     | All via COMLGEL0                      |

## Data Flow Diagrams

### Customer Add Flow (CUSADD00)

```
[IMS Terminal]
    |
    | CSAD transaction (FUNC=AD or FA)
    v
[CUSADD00] --GU--> [IO PCB]
    |
    v
[Validate Required Fields]
    |  - First/Last Name
    |  - Address, City, State, ZIP
    |  - State code valid
    |  - ZIP format (5 or 5-4)
    |  - Phone format (10 digits)
    |  - Email format (contains @)
    |
    v
[Duplicate Check] ---SELECT---> [CUSTOMER]
    |  (LAST_NAME + PHONE or LAST_NAME + ADDRESS)
    |
    +--DUPLICATE FOUND (FUNC=AD)-----> [Return warning, allow FA]
    |
    +--NO DUPLICATE or FUNC=FA------+
                                     |
                                     v
                          [Salesperson Assignment]
                              |
                              +--PROVIDED-----> use WS-AI-ASSIGNED-SALES
                              |
                              +--NOT PROVIDED-> [Round-Robin SELECT]
                                                    |
                                              [SYSTEM_USER] (active salespersons
                                                   for dealer, round-robin)
                                                    |
                                                    v
                                          [INSERT] --> [CUSTOMER]
                                                    |
                                          [CALL COMLGEL0] --> [AUDIT_LOG]
                                                    |
                                          [ISRT confirmation] --> [Terminal]
                                          (shows new CUSTOMER_ID)
```

### Customer Search Flow (CUSINQ00)

```
[IMS Terminal]
    |
    | CSIQ transaction
    v
[CUSINQ00] --GU--> [IO PCB]
    |
    |-- FUNC=SR (Search) ------+
    |                           |
    |   Search Type:            |
    |   LN = Last Name LIKE    -+-> [CURSOR on CUSTOMER]
    |   FN = First Name LIKE   -+     (WHERE clause varies
    |   PH = Phone exact       -+      by search type)
    |   DL = Driver License    -+
    |   ID = Customer ID       -+
    |                                  |
    |                           [Fetch 10 per page]
    |                                  |
    |                           [ISRT list] --> [Terminal]
    |
    |-- FUNC=SL (Select) --SELECT---> [CUSTOMER] (full detail)
    |                                  |
    |                    [CALL COMFMTL0] (format phone, mask SSN)
    |                                  |
    |                           [ISRT detail] --> [Terminal]
    |
    |-- FUNC=NX (Next Page) ---CURSOR reposition-->
    |-- FUNC=PV (Prev Page) ---CURSOR reposition-->
```

### Credit Pre-Qualification Flow (CUSCRED0)

```
[IMS Terminal]
    |
    | CSCR transaction
    v
[CUSCRED0] --GU--> [IO PCB]
    |
    |-- FUNC=CK (Check) ------+
    |                           |
    |   [SELECT] --> [CUSTOMER] (get income, name)
    |                           |
    |   [SELECT] --> [CREDIT_CHECK] (check for existing valid report)
    |                           |
    |   +--VALID EXISTS-------> [Display existing report]
    |   |
    |   +--NO VALID REPORT---> [Simulate credit bureau call]
    |                           |
    |                    [Generate score from income bracket]
    |                      >100K = Tier A (760)
    |                      >75K  = Tier B (720)
    |                      >50K  = Tier C (670)
    |                      >35K  = Tier D (620)
    |                      <35K  = Tier E (560)
    |                           |
    |                    [Calculate DTI ratio if debt provided]
    |                      DTI = monthly_debt / (annual_income / 12)
    |                           |
    |                    [INSERT] --> [CREDIT_CHECK]
    |                      STATUS = 'RC' (Received)
    |                      EXPIRY_DATE = +30 days
    |                           |
    |                    [CALL COMLGEL0] --> [AUDIT_LOG]
    |                           |
    |                    [ISRT results] --> [Terminal]
    |                    (tier, score, max finance amount)
    |
    |-- FUNC=VW (View) ---SELECT---> [CREDIT_CHECK]
                                     [ISRT display] --> [Terminal]
```

### Lead Management Flow (CUSLEAD0)

```
[IMS Terminal]
    |
    | CSLD transaction
    v
[CUSLEAD0] --GU--> [IO PCB]
    |
    |-- FUNC=AD (Add Lead) ------+
    |                             |
    |   [SELECT] --> [CUSTOMER] (validate exists)
    |                             |
    |   [INSERT] --> [CUSTOMER_LEAD]
    |     STATUS = 'NW' (New)
    |     CONTACT_COUNT = 0
    |                             |
    |   [CALL COMLGEL0] --> [AUDIT_LOG]
    |
    |-- FUNC=UP (Update Status) --+
    |                              |
    |   [SELECT] --> [CUSTOMER_LEAD]
    |                              |
    |   [Validate status transition]
    |     NW -> CT -> AP -> TS -> QT -> WN / LS / DD
    |                              |
    |   [UPDATE] --> [CUSTOMER_LEAD]
    |     CONTACT_COUNT + 1
    |     LAST_CONTACT_DT = current
    |                              |
    |   If STATUS = 'WN' --> [Link to deal creation]
    |
    |-- FUNC=LS (List) -----+
    |                        |
    |   [CURSOR] --> [CUSTOMER_LEAD]
    |     (by salesperson/status, alerts on overdue follow-ups)
    |                        |
    |   [ISRT list] --> [Terminal]
```

### Purchase History Flow (CUSHIS00)

```
[IMS Terminal]
    |
    | CSHI transaction
    v
[CUSHIS00] --GU--> [IO PCB]
    |
    [SELECT] --> [CUSTOMER] (validate, get name)
    |
    [CURSOR] --> [SALES_DEAL]
                    JOIN [VEHICLE]
                    LEFT JOIN [TRADE_IN]
                 (WHERE CUSTOMER_ID = input, ORDER BY DEAL_DATE DESC)
    |
    [For each deal row:]
    |  - Deal date, VIN, Year/Make/Model
    |  - Deal type (R/L/F/W)
    |  - Sale price, trade-in info
    |
    [Calculate summary:]
    |  - Total purchases count
    |  - Total amount spent
    |  - Average deal value
    |  - Repeat buyer flag (count > 1)
    |
    [ISRT history display] --> [Terminal]
```

## Field-Level Data Mapping

| Source Field (COBOL)      | Table.Column                  | Format             | Validation Rules                        |
|--------------------------|-------------------------------|--------------------|-----------------------------------------|
| WS-AI-FIRST-NAME         | CUSTOMER.FIRST_NAME           | X(30)              | Required                                |
| WS-AI-LAST-NAME          | CUSTOMER.LAST_NAME            | X(30)              | Required                                |
| WS-AI-DOB                | CUSTOMER.DATE_OF_BIRTH        | X(10) -> DATE      | YYYY-MM-DD format                       |
| WS-AI-SSN-LAST4          | CUSTOMER.SSN_LAST4            | X(04)              | 4 digits, masked on display             |
| WS-AI-DL-NUMBER          | CUSTOMER.DRIVERS_LICENSE      | X(20)              | Optional                                |
| WS-AI-ADDRESS1           | CUSTOMER.ADDRESS_LINE1        | X(50)              | Required                                |
| WS-AI-STATE              | CUSTOMER.STATE_CODE           | X(02)              | Valid 2-char state code                 |
| WS-AI-ZIP                | CUSTOMER.ZIP_CODE             | X(10)              | 5-digit or 5+4 format                  |
| WS-AI-CELL-PHONE         | CUSTOMER.CELL_PHONE           | X(10)              | 10 digits                               |
| WS-AI-EMAIL              | CUSTOMER.EMAIL                | X(60)              | Must contain '@'                        |
| WS-AI-INCOME             | CUSTOMER.ANNUAL_INCOME        | X(11) -> DEC(11,2) | Numeric                                 |
| WS-AI-CUST-TYPE          | CUSTOMER.CUSTOMER_TYPE        | X(01)              | I=Individual, B=Business, F=Fleet       |
| WS-AI-SOURCE             | CUSTOMER.SOURCE_CODE          | X(03)              | WLK/WEB/REF/RPT/ADV                    |
| WS-CI-BUREAU-CODE        | CREDIT_CHECK.BUREAU_CODE      | X(02)              | EQ/EX/TU                               |
| WS-LI-STATUS             | CUSTOMER_LEAD.LEAD_STATUS     | X(02)              | NW/CT/AP/TS/QT/WN/LS/DD                |
| WS-LI-SOURCE             | CUSTOMER_LEAD.LEAD_SOURCE     | X(03)              | WEB/PHN/WLK/EML/EVT                    |

## Error Paths

- **CUSADD00**: Duplicate detection (same last name + phone or address) returns warning on first attempt (FUNC=AD); user must resubmit with FUNC=FA to force. INSERT failure (SQLCODE -803) returns duplicate key error. Missing required fields return specific field-level messages.
- **CUSINQ00**: Empty result set returns "NO CUSTOMERS FOUND". Invalid search type returns error. Page beyond bounds returns "NO MORE RECORDS".
- **CUSCRED0**: Customer not found (SQLCODE +100) returns error. Income of zero prevents score calculation. Existing valid (non-expired) credit report skips new bureau call.
- **CUSLEAD0**: Invalid status transition (e.g., jumping from NW to WN) rejected. Customer must exist before lead creation.
- **CUSUPD00**: Customer not found returns error. Each changed field logged individually with old/new values to AUDIT_LOG.
- **CUSHIS00**: Customer with no purchase history returns "NO PURCHASE HISTORY FOUND".

## Cross-Domain Dependencies

| Dependency Direction       | Related Domain        | Data Exchanged                                               |
|---------------------------|-----------------------|--------------------------------------------------------------|
| Customer --> Sales        | SALES_DEAL references CUSTOMER_ID; CUSHIS00 reads SALES_DEAL for history |
| Customer --> Finance      | CREDIT_CHECK used by FINCHK00; CUSTOMER data pulled for FINANCE_APP |
| Customer --> Vehicle      | CUSHIS00 joins VEHICLE for model descriptions                |
| Customer --> Registration | REGISTRATION references CUSTOMER_ID                          |
| Customer --> Warranty     | WRCINQ00 finds owner via SALES_DEAL -> CUSTOMER              |
| Customer <-- Admin        | CUSADD00 reads SYSTEM_USER for salesperson round-robin        |
| Customer --> Sales Leads  | Lead status WN triggers deal creation in Sales domain        |
