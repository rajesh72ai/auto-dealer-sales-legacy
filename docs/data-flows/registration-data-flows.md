# Registration Processing Domain -- Data Flows

## Overview

The Registration Processing domain handles vehicle title and registration with state DMV agencies after a sale is completed. It covers document assembly from deal/customer/vehicle data, field validation against state rules, submission to the DMV, tracking of processing status, and recording of issued plates and titles. This is a post-sale compliance domain that ensures every sold vehicle is properly titled and registered.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| REGGEN00 | Registration Document Generation     | RGGE            |
| REGINQ00 | Registration Inquiry                 | RGIN            |
| REGSTS00 | Registration Status Update           | RGST            |
| REGSUB00 | Registration Submission to State     | RGSB            |
| REGVAL00 | Registration Validation              | RGVL            |

## Data Stores

| Table/Database             | Type | Key Fields                | Used By                                    |
|----------------------------|------|---------------------------|--------------------------------------------|
| AUTOSALE.REGISTRATION      | DB2  | REG_ID (CHAR 12)          | All REG programs                           |
| AUTOSALE.TITLE_STATUS      | DB2  | REG_ID, STATUS_SEQ        | REGSTS00, REGSUB00                         |
| AUTOSALE.SALES_DEAL        | DB2  | DEAL_NUMBER               | REGGEN00, REGINQ00                         |
| AUTOSALE.VEHICLE           | DB2  | VIN                       | REGGEN00, REGINQ00, REGSUB00              |
| AUTOSALE.CUSTOMER          | DB2  | CUSTOMER_ID               | REGGEN00, REGINQ00, REGVAL00, REGSUB00    |
| AUTOSALE.TAX_RATE          | DB2  | STATE/COUNTY/CITY/DATE    | REGGEN00 (via COMTAXL0), REGVAL00         |

## Data Flow Diagrams

### Complete Registration Lifecycle

```
[Sale Completed (SALCMP00)]
    |
    v
[REGGEN00] --> [REGISTRATION] STATUS=PR (Preparing)
    |
    v
[REGVAL00] --> [REGISTRATION] STATUS=VL (Validated)
    |
    v
[REGSUB00] --> [REGISTRATION] STATUS=SB (Submitted)
    |              [TITLE_STATUS] (submission record)
    v
[State DMV Processing]
    |
    v
[REGSTS00] --> [REGISTRATION] STATUS=PG/IS/RJ
    |              [TITLE_STATUS] (decision record)
    |
    +--IS (Issued)----> Plate #, Title # recorded
    |
    +--RJ (Rejected)--> Fix and resubmit via REGSUB00
```

### Registration Document Generation (REGGEN00)

```
[IMS Terminal / Triggered by SALCMP00]
    |
    | RGGE transaction (Deal Number)
    v
[REGGEN00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL]
    |   (validate STATUS = DL or FI)
    |
    [SELECT] --> [VEHICLE]
    |   (get VIN, year/make/model, color)
    |
    [SELECT] --> [CUSTOMER]
    |   (get name, address, DL info)
    |
    [CALL COMTAXL0] --> [TAX_RATE]
    |   (get REG_FEE, TITLE_FEE for state)
    |
    [CALL COMVALD0] (validate VIN for registration)
    |
    [Determine registration type:]
    |   NW = New (new vehicle, no prior registration)
    |   TF = Transfer (if trade-in plate transfer)
    |   RN = Renewal (rare in dealer context)
    |
    [INSERT] --> [REGISTRATION]
    |   REG_ID = generated
    |   DEAL_NUMBER, VIN, CUSTOMER_ID
    |   REG_STATE = customer's state
    |   REG_TYPE = determined
    |   LIEN_HOLDER = from FINANCE_APP if financed
    |   LIEN_HOLDER_ADDR = lender address
    |   REG_STATUS = 'PR' (Preparing)
    |   REG_FEE_PAID, TITLE_FEE_PAID = from TAX_RATE
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT registration packet summary] --> [Terminal]
```

### Registration Validation (REGVAL00)

```
[IMS Terminal]
    |
    | RGVL transaction (REG_ID)
    v
[REGVAL00] --GU--> [IO PCB]
    |
    [SELECT] --> [REGISTRATION] (must be STATUS=PR)
    |
    [Validation checklist:]
    |
    |   [1] Customer name present?
    |       [SELECT] --> [CUSTOMER] (verify data)
    |
    |   [2] Customer address complete?
    |       (address, city, state, zip all non-blank)
    |
    |   [3] VIN present and valid?
    |       [CALL COMVALD0]
    |
    |   [4] Registration state valid?
    |       [SELECT] --> [TAX_RATE] (state exists)
    |
    |   [5] Registration type set?
    |       (NW/TF/RN/DP)
    |
    |   [6] Fees calculated?
    |       (REG_FEE_PAID > 0 and TITLE_FEE_PAID > 0)
    |
    +--ALL PASS-----> [UPDATE] --> [REGISTRATION]
    |                    REG_STATUS = 'VL' (Validated)
    |
    +--FAILURES-----> [Return failure list]
    |                    REG_STATUS remains 'PR'
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT validation result] --> [Terminal]
```

### Registration Submission (REGSUB00)

```
[IMS Terminal]
    |
    | RGSB transaction (REG_ID)
    v
[REGSUB00] --GU--> [IO PCB]
    |
    [SELECT] --> [REGISTRATION] (must be STATUS=VL)
    |
    [SELECT] --> [VEHICLE]   (verify VIN details)
    [SELECT] --> [CUSTOMER]  (verify customer info)
    |
    [Generate tracking number for submission]
    |
    [UPDATE] --> [REGISTRATION]
    |   REG_STATUS = 'SB' (Submitted)
    |   SUBMISSION_DATE = current date
    |
    [INSERT] --> [TITLE_STATUS]
    |   STATUS_SEQ = 1 (or next)
    |   STATUS_CODE = 'SB'
    |   STATUS_DESC = 'SUBMITTED TO STATE DMV'
    |   STATUS_TS = current timestamp
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT submission confirmation] --> [Terminal]
```

### Registration Status Update (REGSTS00)

```
[IMS Terminal / DMV Response Feed]
    |
    | RGST transaction (REG_ID, New Status, Plate/Title if issued)
    v
[REGSTS00] --GU--> [IO PCB]
    |
    [SELECT] --> [REGISTRATION]
    |   (must be STATUS = SB or PG)
    |
    [Evaluate new status:]
    |
    |-- PG (Processing) -----+
    |                         |
    |   [UPDATE REGISTRATION] STATUS = 'PG'
    |   [INSERT TITLE_STATUS] STATUS_CODE = 'PG'
    |
    |-- IS (Issued) ---------+
    |                         |
    |   [UPDATE REGISTRATION]
    |     STATUS = 'IS'
    |     PLATE_NUMBER = input
    |     TITLE_NUMBER = input
    |     ISSUED_DATE = current date
    |   [INSERT TITLE_STATUS] STATUS_CODE = 'IS'
    |     STATUS_DESC = 'PLATE AND TITLE ISSUED'
    |
    |-- RJ (Rejected) -------+
    |                         |
    |   [UPDATE REGISTRATION]
    |     STATUS = 'RJ'
    |   [INSERT TITLE_STATUS] STATUS_CODE = 'RJ'
    |     STATUS_DESC = rejection reason
    |   [Can be resubmitted after correction]
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT status update confirmation] --> [Terminal]
```

### Registration Inquiry (REGINQ00)

```
[IMS Terminal]
    |
    | RGIN transaction (REG_ID, VIN, or Deal Number)
    v
[REGINQ00] --GU--> [IO PCB]
    |
    [SELECT] --> [REGISTRATION]
                    JOIN [VEHICLE]
                    JOIN [CUSTOMER]
                    JOIN [SALES_DEAL]
    |   (by REG_ID, VIN, or DEAL_NUMBER)
    |
    [Display:]
    |   Registration ID, Status
    |   VIN, Year/Make/Model
    |   Customer name, address
    |   Reg state, Reg type
    |   Plate number, Title number
    |   Lien holder info
    |   Fees paid (reg + title)
    |   Submission date, Issued date
    |
    [Supports PF7/PF8 paging for multiple results]
    |
    [ISRT registration detail] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

## Field-Level Data Mapping

| Source Field (COBOL)       | Table.Column                  | Format          | Validation Rules                          |
|---------------------------|-------------------------------|-----------------|-------------------------------------------|
| WS-IN-DEAL-NUMBER         | REGISTRATION.DEAL_NUMBER      | X(10)           | Must exist in SALES_DEAL                  |
| WS-IN-REG-ID              | REGISTRATION.REG_ID           | X(12)           | Auto-generated or input for inquiry       |
| WS-IN-REG-STATE           | REGISTRATION.REG_STATE        | X(02)           | Must exist in TAX_RATE                    |
| WS-IN-REG-TYPE            | REGISTRATION.REG_TYPE         | X(02)           | NW/TF/RN/DP                              |
| WS-IN-PLATE-NUMBER        | REGISTRATION.PLATE_NUMBER     | X(10)           | Set by REGSTS00 on IS status              |
| WS-IN-TITLE-NUMBER        | REGISTRATION.TITLE_NUMBER     | X(20)           | Set by REGSTS00 on IS status              |
| WS-IN-LIEN-HOLDER         | REGISTRATION.LIEN_HOLDER      | X(60)           | From finance app if vehicle financed      |
| (calculated)              | REGISTRATION.REG_FEE_PAID     | DEC(7,2)        | From TAX_RATE via COMTAXL0                |
| (calculated)              | REGISTRATION.TITLE_FEE_PAID   | DEC(7,2)        | From TAX_RATE via COMTAXL0                |
| WS-IN-STATUS              | TITLE_STATUS.STATUS_CODE      | X(02)           | SB/PG/IS/RJ                              |
| WS-IN-STATUS-DESC         | TITLE_STATUS.STATUS_DESC      | X(60)           | Required for RJ status                    |

## Error Paths

- **REGGEN00**: Deal not in DL or FI status returns "DEAL NOT ELIGIBLE FOR REGISTRATION". Missing customer address data returns specific field error. TAX_RATE not found for state returns "STATE TAX DATA NOT FOUND".
- **REGVAL00**: Each validation failure adds to error list. All failures returned at once. Status remains PR until all pass.
- **REGSUB00**: Registration not in VL status returns "REGISTRATION NOT VALIDATED". Cannot submit twice (SB status rejects resubmission unless first rejected).
- **REGSTS00**: Registration not in SB or PG status returns "INVALID STATUS FOR UPDATE". Plate/title numbers required for IS status.
- **REGINQ00**: No registration found returns "REGISTRATION NOT FOUND". Display-only, no write errors.

## Cross-Domain Dependencies

| Dependency Direction        | Related Domain       | Data Exchanged                                          |
|----------------------------|----------------------|---------------------------------------------------------|
| Registration <-- Sales     | REGGEN00 triggered by SALCMP00; reads SALES_DEAL for deal data |
| Registration <-- Customer  | Customer name, address, DL info for registration packet  |
| Registration <-- Vehicle   | VIN, year/make/model for registration                    |
| Registration <-- Admin     | TAX_RATE for state registration and title fees           |
| Registration <-- Finance   | Lien holder info from FINANCE_APP for title              |
