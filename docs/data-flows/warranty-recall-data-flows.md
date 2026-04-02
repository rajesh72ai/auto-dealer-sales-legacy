# Warranty & Recall Domain -- Data Flows

## Overview

The Warranty & Recall domain manages post-sale vehicle coverage and safety recall campaigns. It handles warranty registration at time of sale (creating standard manufacturer coverages), warranty inquiry/coverage lookup, recall campaign ingestion from manufacturer feeds, recall vehicle matching, customer notification generation, recall status tracking and completion, and warranty claims summary reporting. This domain ensures compliance with manufacturer warranty obligations and NHTSA recall requirements.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| WRCINQ00 | Warranty Inquiry / Coverage Lookup   | WRCI            |
| WRCNOTF0 | Recall Notification Generation       | WRNF            |
| WRCRCL00 | Recall Management (INQ/VEH/UPD)      | WRCR            |
| WRCRCLB0 | Recall Batch (Manufacturer Feed)     | WRRB            |
| WRCRPT00 | Warranty Claims Summary Report       | WRRT            |
| WRCWAR00 | Warranty Registration                | WRWA            |

## Data Stores

| Table/Database                  | Type | Key Fields                  | Used By                                   |
|---------------------------------|------|-----------------------------|-------------------------------------------|
| AUTOSALE.WARRANTY               | DB2  | WARRANTY_ID (auto-gen)      | WRCWAR00, WRCINQ00                        |
| AUTOSALE.RECALL_CAMPAIGN        | DB2  | RECALL_ID (CHAR 10)         | WRCRCLB0, WRCRCL00, WRCNOTF0             |
| AUTOSALE.RECALL_VEHICLE         | DB2  | RECALL_ID, VIN              | WRCRCLB0, WRCRCL00, WRCNOTF0             |
| AUTOSALE.RECALL_NOTIFICATION    | DB2  | NOTIF_ID (auto-gen)         | WRCNOTF0                                  |
| AUTOSALE.VEHICLE                | DB2  | VIN                         | WRCINQ00, WRCRCL00, WRCRCLB0, WRCWAR00   |
| AUTOSALE.MODEL_MASTER           | DB2  | YEAR/MAKE/MODEL             | WRCINQ00                                  |
| AUTOSALE.SALES_DEAL             | DB2  | DEAL_NUMBER                 | WRCINQ00, WRCNOTF0, WRCWAR00             |
| AUTOSALE.CUSTOMER               | DB2  | CUSTOMER_ID                 | WRCINQ00, WRCNOTF0                        |
| AUTOSALE.DEALER                 | DB2  | DEALER_CODE                 | WRCRPT00                                  |

## Data Flow Diagrams

### Warranty Registration Flow (WRCWAR00)

```
[Sale Completed (SALCMP00)]
    |
    | WRWA transaction (Deal Number)
    v
[WRCWAR00] --GU--> [IO PCB]
    |
    [SELECT] --> [SALES_DEAL] (get VIN, deal date)
    [SELECT] --> [VEHICLE]    (verify VIN)
    |
    [Generate 4 standard warranty records:]
    |
    |   [1] BASIC (Bumper-to-Bumper)
    |       TYPE = 'BT'
    |       TERM = 3 years / 36,000 miles
    |       DEDUCTIBLE = $0
    |
    |   [2] POWERTRAIN
    |       TYPE = 'PT'
    |       TERM = 5 years / 60,000 miles
    |       DEDUCTIBLE = $100
    |
    |   [3] CORROSION
    |       TYPE = 'CR'
    |       TERM = 5 years / unlimited miles
    |       DEDUCTIBLE = $0
    |
    |   [4] EMISSION
    |       TYPE = 'EM'
    |       TERM = 8 years / 80,000 miles
    |       DEDUCTIBLE = $0
    |
    [For each warranty:]
    |   START_DATE = DEAL_DATE (sale date)
    |   [CALL COMDTEL0] (calculate EXPIRY_DATE = start + years)
    |   MILEAGE_LIMIT = per type
    |   ACTIVE_FLAG = 'Y'
    |
    |   [INSERT] --> [WARRANTY]
    |     WARRANTY_ID (auto-gen), VIN, DEAL_NUMBER
    |     WARRANTY_TYPE, START_DATE, EXPIRY_DATE
    |     MILEAGE_LIMIT, DEDUCTIBLE, ACTIVE_FLAG
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT warranty registration summary] --> [Terminal]
```

### Warranty Inquiry Flow (WRCINQ00)

```
[IMS Terminal]
    |
    | WRCI transaction (VIN)
    v
[WRCINQ00] --GU--> [IO PCB]
    |
    [SELECT] --> [VEHICLE] JOIN [MODEL_MASTER]
    |   (vehicle details: year, make, model, color, etc.)
    |
    [SELECT] --> [SALES_DEAL]
    |   (latest delivered deal for this VIN)
    |   --> [CUSTOMER] (current owner name/contact)
    |
    [CURSOR] --> [WARRANTY]
    |   (all warranty records for this VIN)
    |
    [For each warranty:]
    |   TYPE (BT/PT/CR/EM), description
    |   Start date, Expiry date
    |   Mileage limit
    |   Deductible
    |   Status: ACTIVE / EXPIRED
    |     [CALL COMDTEL0] (days remaining = expiry - today)
    |     IF days remaining <= 0: EXPIRED
    |
    [Display:]
    |   Vehicle: 2026 Honda Accord LX, VIN: ...
    |   Owner: John Smith, Phone: (555) 123-4567
    |
    |   Coverage         | Start      | Expiry     | Miles  | Ded  | Status
    |   --------------- | ---------- | ---------- | ------ | ---- | -------
    |   Basic (B-to-B)  | 2026-01-15 | 2029-01-15 | 36,000 | $0   | ACTIVE
    |   Powertrain       | 2026-01-15 | 2031-01-15 | 60,000 | $100 | ACTIVE
    |   Corrosion        | 2026-01-15 | 2031-01-15 | N/A    | $0   | ACTIVE
    |   Emission         | 2026-01-15 | 2034-01-15 | 80,000 | $0   | ACTIVE
    |
    [ISRT warranty display] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

### Recall Batch Ingestion Flow (WRCRCLB0)

```
[Manufacturer Recall Feed]
    |
    | WRRB transaction (Campaign header + up to 50 VINs)
    v
[WRCRCLB0] --GU--> [IO PCB]
    |
    [Parse campaign header:]
    |   RECALL_ID, NHTSA_NUM, DESCRIPTION
    |   SEVERITY (C/H/M/L), AFFECTED_YEARS
    |   AFFECTED_MODELS, REMEDY_DESC
    |   REMEDY_AVAIL_DT, ANNOUNCED_DATE
    |
    [INSERT] --> [RECALL_CAMPAIGN]
    |   CAMPAIGN_STATUS = 'A' (Active)
    |   TOTAL_AFFECTED = 0 (will increment)
    |
    [For each VIN in feed:]
    |
    |   [CALL COMVALD0] (validate VIN)
    |
    |   [SELECT] --> [VEHICLE] (check if VIN exists)
    |
    |   +--VIN FOUND---------+
    |   |                     |
    |   |   [INSERT] --> [RECALL_VEHICLE]
    |   |     RECALL_ID, VIN
    |   |     DEALER_CODE = from VEHICLE
    |   |     RECALL_STATUS = 'OP' (Open)
    |   |     TOTAL_AFFECTED + 1
    |   |
    |   +--VIN NOT FOUND-----+
    |   |                     |
    |   |   [Log warning: "VIN NOT IN INVENTORY"]
    |   |   unmatched_count + 1
    |
    [UPDATE] --> [RECALL_CAMPAIGN]
    |   TOTAL_AFFECTED = matched count
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    |
    [ISRT batch results] --> [Terminal]
    |   Total in feed: 50
    |   Matched: 42
    |   Unmatched: 8
```

### Recall Notification Generation (WRCNOTF0)

```
[IMS Terminal]
    |
    | WRNF transaction (Recall ID)
    v
[WRCNOTF0] --GU--> [IO PCB]
    |
    [SELECT] --> [RECALL_CAMPAIGN]
    |   (validate exists, STATUS = 'A')
    |
    [CURSOR] --> [RECALL_VEHICLE]
    |   (all VINs for this campaign)
    |
    [For each affected VIN:]
    |
    |   [Find current owner:]
    |     [SELECT] --> [SALES_DEAL]
    |       (latest delivered deal for VIN)
    |       --> CUSTOMER_ID
    |
    |   +--OWNER FOUND-----------+
    |   |                         |
    |   |   [SELECT] --> [CUSTOMER] (contact info)
    |   |
    |   |   [Check existing notification:]
    |   |     [SELECT] --> [RECALL_NOTIFICATION]
    |   |       (RECALL_ID + VIN)
    |   |
    |   |   +--ALREADY NOTIFIED---> already_count + 1
    |   |   |
    |   |   +--NOT NOTIFIED-------> [INSERT] --> [RECALL_NOTIFICATION]
    |   |                              RECALL_ID, VIN, CUSTOMER_ID
    |   |                              NOTIF_TYPE = 'M' (Mail default)
    |   |                              NOTIF_DATE = current date
    |   |                              RESPONSE_FLAG = 'N'
    |   |                              created_count + 1
    |   |
    |   +--NO OWNER FOUND--------> no_owner_count + 1
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    |
    [ISRT notification results] --> [Terminal]
    |   Notifications created: XX
    |   Already notified: XX
    |   No owner found: XX
```

### Recall Management Flow (WRCRCL00)

```
[IMS Terminal]
    |
    | WRCR transaction
    v
[WRCRCL00] --GU--> [IO PCB]
    |
    |-- FUNC=INQ (Campaign Detail) ----+
    |                                   |
    |   [SELECT] --> [RECALL_CAMPAIGN]
    |   Display: ID, NHTSA#, Description, Severity
    |            Affected years/models, Remedy
    |            Total affected, Total completed
    |            Status
    |
    |-- FUNC=VEH (List Vehicles) ------+
    |                                   |
    |   [CURSOR] --> [RECALL_VEHICLE]
    |                   JOIN [VEHICLE]
    |   Display per VIN:
    |     VIN, Year/Make/Model, Dealer
    |     Recall status (OP/SC/IP/CM/NA)
    |     Notified date, Scheduled date
    |     Parts ordered/available flags
    |
    |-- FUNC=UPD (Update Status) ------+
    |                                   |
    |   [SELECT] --> [RECALL_VEHICLE]
    |
    |   [Valid status transitions:]
    |     OP -> SC (Scheduled)
    |     SC -> IP (In Progress)
    |     IP -> CM (Complete)
    |     OP -> NA (Not Applicable)
    |
    |   [UPDATE] --> [RECALL_VEHICLE]
    |     RECALL_STATUS = new status
    |     SCHEDULED_DATE, COMPLETED_DATE,
    |     TECHNICIAN_ID as applicable
    |
    |   [If STATUS = CM:]
    |     [UPDATE] --> [RECALL_CAMPAIGN]
    |       TOTAL_COMPLETED + 1
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT recall display] --> [Terminal]
```

### Warranty Claims Report (WRCRPT00)

```
[IMS Terminal]
    |
    | WRRT transaction (Dealer Code, optional date range)
    v
[WRCRPT00] --GU--> [IO PCB]
    |
    [SELECT] --> [DEALER] (verify dealer, get name)
    |
    [CURSOR] --> WARRANTY_CLAIM table
    |   (aggregate by claim type)
    |   (WHERE DEALER_CODE = input
    |    AND optional date range filter)
    |
    [Display summary:]
    |   Claim Type   | Count | Approved | Denied | Total $
    |   ------------ | ----- | -------- | ------ | -------
    |   Basic        | 12    | 10       | 2      | $4,500
    |   Powertrain   | 5     | 4        | 1      | $8,200
    |   Corrosion    | 2     | 2        | 0      | $1,100
    |   Emission     | 1     | 1        | 0      | $350
    |   ------------ | ----- | -------- | ------ | -------
    |   Grand Total  | 20    | 17       | 3      | $14,150
    |   Avg per claim: $707.50
    |
    [ISRT report display] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

## Field-Level Data Mapping

| Source Field (COBOL)         | Table.Column                       | Format          | Validation Rules                        |
|-----------------------------|------------------------------------|-----------------|-----------------------------------------|
| WS-IN-VIN                   | WARRANTY.VIN                       | X(17)           | Must exist in VEHICLE                   |
| WS-IN-DEAL-NUMBER           | WARRANTY.DEAL_NUMBER               | X(10)           | Must exist, STATUS=DL                   |
| (generated)                 | WARRANTY.WARRANTY_TYPE             | X(02)           | BT/PT/CR/EM                             |
| (calculated)                | WARRANTY.START_DATE                | DATE            | = SALES_DEAL.DEAL_DATE                  |
| (calculated)                | WARRANTY.EXPIRY_DATE               | DATE            | START + years per type                  |
| (per type)                  | WARRANTY.MILEAGE_LIMIT             | INT             | 36K/60K/unlimited/80K                   |
| (per type)                  | WARRANTY.DEDUCTIBLE                | DEC(7,2)        | $0 or $100                              |
| WS-IN-RECALL-ID             | RECALL_CAMPAIGN.RECALL_ID          | X(10)           | Required for all recall operations      |
| WS-IN-NHTSA-NUM             | RECALL_CAMPAIGN.NHTSA_NUM          | X(12)           | Optional NHTSA reference                |
| WS-IN-SEVERITY              | RECALL_CAMPAIGN.SEVERITY           | X(01)           | C=Critical, H=High, M=Medium, L=Low    |
| WS-IN-RECALL-STATUS         | RECALL_VEHICLE.RECALL_STATUS       | X(02)           | OP/SC/IP/CM/NA                          |
| WS-IN-NOTIF-TYPE            | RECALL_NOTIFICATION.NOTIF_TYPE     | X(01)           | M=Mail, E=Email, P=Phone, S=SMS        |

## Error Paths

- **WRCWAR00**: Deal not found or not delivered returns error. Vehicle not found returns error. Duplicate warranty (same VIN + type + overlapping dates) returns warning.
- **WRCINQ00**: VIN not found returns "VEHICLE NOT FOUND". No warranty records returns "NO WARRANTY COVERAGE FOUND". Display-only, no write errors.
- **WRCRCLB0**: Duplicate RECALL_ID returns "CAMPAIGN ALREADY EXISTS". Individual VIN failures logged but do not abort batch -- processing continues. Summary shows matched vs. unmatched counts.
- **WRCNOTF0**: Campaign not found or not active returns error. For each VIN: owner not found logged as "NO OWNER"; already notified logged as "DUPLICATE". Individual failures do not abort the batch.
- **WRCRCL00**: Invalid status transition (e.g., OP directly to CM) rejected. Campaign not found returns error. VIN not in campaign returns error.
- **WRCRPT00**: No claims for dealer/date range returns "NO WARRANTY CLAIMS FOUND". Display-only.

## Cross-Domain Dependencies

| Dependency Direction          | Related Domain       | Data Exchanged                                         |
|------------------------------|----------------------|--------------------------------------------------------|
| Warranty <-- Sales           | WRCWAR00 triggered by SALCMP00; reads SALES_DEAL for deal date and VIN |
| Warranty <-- Vehicle         | VEHICLE data for VIN validation and model info          |
| Warranty <-- Customer        | CUSTOMER data for recall notification contact info      |
| Warranty <-- Admin           | MODEL_MASTER for vehicle descriptions in inquiry        |
| Warranty <-- External        | WRCRCLB0 ingests manufacturer recall campaign feeds     |
| Warranty --> Customer        | WRCNOTF0 generates customer notifications               |
| Warranty <-- Sales           | WRCINQ00 finds current owner via latest SALES_DEAL     |
