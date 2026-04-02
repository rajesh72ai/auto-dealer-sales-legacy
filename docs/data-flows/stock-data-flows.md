# Stock/Inventory Management Domain -- Data Flows

## Overview

The Stock/Inventory Management domain provides aggregate-level inventory tracking, analysis, and control for dealer vehicle inventory. While the Vehicle domain manages individual VIN-level records, the Stock domain manages position-level counts by model, aging analysis, low-stock alerts, physical count reconciliation, hold/release operations, daily snapshots for historical trending, and summary dashboards. It is the operational intelligence layer for inventory management.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| STKADJT0 | Stock Adjustment (manual)            | (DLITCBL entry) |
| STKAGIN0 | Stock Aging Engine                   | (DLITCBL entry) |
| STKALRT0 | Low Stock Alert Processor            | (DLITCBL entry) |
| STKHLD00 | Hold/Release Vehicle                 | (DLITCBL entry) |
| STKINQ00 | Stock Position Inquiry               | (DLITCBL entry) |
| STKRCN00 | Stock Reconciliation                 | (DLITCBL entry) |
| STKSNAP0 | Daily Stock Snapshot                 | (DLITCBL entry) |
| STKSUM00 | Stock Summary Dashboard              | (DLITCBL entry) |

## Data Stores

| Table/Database                | Type | Key Fields                              | Used By                                     |
|-------------------------------|------|-----------------------------------------|---------------------------------------------|
| AUTOSALE.STOCK_POSITION       | DB2  | DEALER_CODE, MODEL_YEAR, MAKE_CODE, MODEL_CODE | STKINQ00, STKALRT0, STKRCN00, STKSNAP0, STKSUM00, STKHLD00, STKADJT0 |
| AUTOSALE.STOCK_ADJUSTMENT     | DB2  | ADJUST_ID (auto-gen)                    | STKADJT0, STKRCN00                          |
| AUTOSALE.STOCK_SNAPSHOT       | DB2  | SNAPSHOT_DATE, DEALER/YEAR/MAKE/MODEL   | STKSNAP0                                    |
| AUTOSALE.VEHICLE              | DB2  | VIN                                     | STKADJT0, STKAGIN0, STKHLD00, STKSNAP0, STKSUM00 |
| AUTOSALE.MODEL_MASTER         | DB2  | YEAR/MAKE/MODEL                         | STKALRT0, STKINQ00, STKRCN00, STKSUM00     |
| AUTOSALE.PRICE_MASTER         | DB2  | YEAR/MAKE/MODEL/EFF_DATE                | STKAGIN0, STKSNAP0, STKSUM00               |

## Data Flow Diagrams

### Stock Adjustment Flow (STKADJT0)

```
[IMS Terminal]
    |
    | (VIN, Adjustment Type, Reason, New Status)
    v
[STKADJT0] --GU--> [IO PCB]
    |
    [SELECT] --> [VEHICLE] (verify VIN, get current status)
    |
    [Validate adjustment type:]
    |   DM = Damage
    |   WO = Write-Off
    |   RC = Reclassify
    |   PH = Physical Count
    |   OT = Other
    |
    [UPDATE] --> [VEHICLE]
    |   VEHICLE_STATUS = new status
    |
    [INSERT] --> [STOCK_ADJUSTMENT]
    |   ADJUST_TYPE, ADJUST_REASON
    |   OLD_STATUS, NEW_STATUS
    |   ADJUSTED_BY, ADJUSTED_TS
    |
    [CALL COMSTCK0] --> [STOCK_POSITION]
    |   (adjust counts based on old/new status)
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT confirmation] --> [Terminal]
```

### Stock Aging Engine (STKAGIN0)

```
[IMS Terminal]
    |
    | (Dealer Code)
    v
[STKAGIN0] --GU--> [IO PCB]
    |
    [CURSOR] --> [VEHICLE]
    |   (WHERE DEALER_CODE = input
    |    AND VEHICLE_STATUS IN ('AV','HD'))
    |
    [For each vehicle:]
    |
    |   [CALL COMDTEL0 AGED]
    |     DAYS = current_date - RECEIVE_DATE
    |
    |   [UPDATE] --> [VEHICLE]
    |     DAYS_IN_STOCK = calculated days
    |
    |   [Bucket assignment:]
    |     Bucket 1: 0-30 days
    |     Bucket 2: 31-60 days
    |     Bucket 3: 61-90 days
    |     Bucket 4: 91-120 days
    |     Bucket 5: 120+ days
    |
    |   [Get value from PRICE_MASTER]
    |
    [Aggregate per bucket:]
    |   COUNT, TOTAL_VALUE, AVG_VALUE
    |
    [Flag vehicles approaching curtailment:]
    |   IF DAYS >= WS-CURTAIL-WARNING (75)
    |     --> "CURTAILMENT WARNING"
    |   IF DAYS >= WS-CURTAIL-THRESHOLD (90)
    |     --> "AGED STOCK - ACTION REQUIRED"
    |
    [ISRT aging report] --> [Terminal]
```

### Low Stock Alert (STKALRT0)

```
[IMS Terminal]
    |
    | (Dealer Code)
    v
[STKALRT0] --GU--> [IO PCB]
    |
    [CURSOR] --> [STOCK_POSITION]
                    JOIN [MODEL_MASTER]
    |   (WHERE DEALER_CODE = input
    |    AND ON_HAND_COUNT < REORDER_POINT)
    |
    [For each low-stock model:]
    |   - Model Year / Make / Model Name
    |   - On Hand count
    |   - Reorder Point
    |   - Deficit = REORDER_POINT - ON_HAND_COUNT
    |   - Suggested Order = Deficit + SAFETY_STOCK (2 units)
    |
    [ISRT alert list] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

### Hold/Release Vehicle (STKHLD00)

```
[IMS Terminal]
    |
    | (VIN, Action: HD=Hold / RL=Release, Reason)
    v
[STKHLD00] --GU--> [IO PCB]
    |
    [SELECT] --> [VEHICLE]
    |
    |-- ACTION=HD (Hold) ------+
    |                           |
    |   [Validate STATUS = AV] (can only hold available vehicles)
    |   [UPDATE VEHICLE] STATUS = 'HD'
    |   [CALL COMSTCK0 HOLD] --> [STOCK_POSITION]
    |     ON_HAND_COUNT - 1 (or ON_HOLD_COUNT + 1)
    |
    |-- ACTION=RL (Release) ---+
    |                           |
    |   [Validate STATUS = HD]
    |   [UPDATE VEHICLE] STATUS = 'AV'
    |   [CALL COMSTCK0 RLSE] --> [STOCK_POSITION]
    |     ON_HOLD_COUNT - 1 (or ON_HAND_COUNT + 1)
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT confirmation] --> [Terminal]
```

### Stock Reconciliation (STKRCN00)

```
[IMS Terminal]
    |
    | (Dealer Code, Physical Counts per model)
    v
[STKRCN00] --GU--> [IO PCB]
    |
    [CURSOR] --> [STOCK_POSITION] JOIN [MODEL_MASTER]
    |   (all models for dealer)
    |
    [Display per model:]
    |   Model | System Count | Physical Count | Variance
    |   ----- | ------------ | -------------- | --------
    |   ...   | ON_HAND_COUNT| (user entered) | diff
    |
    [Calculate totals:]
    |   Total system, total physical, total variance
    |
    |-- PF5 (Accept) ----------+
    |                           |
    |   [For each variance != 0:]
    |     [INSERT] --> [STOCK_ADJUSTMENT]
    |       ADJUST_TYPE = 'PH' (Physical Count)
    |       ADJUST_REASON = 'RECONCILIATION'
    |     [UPDATE] --> [STOCK_POSITION]
    |       ON_HAND_COUNT = physical count
    |
    |-- PF6 (Print) -----------+
    |                           |
    |   [Format reconciliation report for print]
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT reconciliation display] --> [Terminal]
```

### Daily Stock Snapshot (STKSNAP0)

```
[IMS Terminal / End-of-Day trigger]
    |
    | (Dealer Code, Snapshot Date)
    v
[STKSNAP0] --GU--> [IO PCB]
    |
    [DELETE existing snapshot for date/dealer if re-running]
    |
    [CURSOR] --> [STOCK_POSITION]
    |   (all models for dealer)
    |
    [For each model position:]
    |
    |   [Calculate AVG_DAYS_IN_STOCK:]
    |     [CURSOR] --> [VEHICLE]
    |       (AVG(DAYS_IN_STOCK) WHERE model matches AND STATUS IN (AV,HD))
    |
    |   [Calculate TOTAL_VALUE:]
    |     ON_HAND_COUNT * INVOICE_PRICE from [PRICE_MASTER]
    |
    |   [INSERT] --> [STOCK_SNAPSHOT]
    |     SNAPSHOT_DATE, DEALER_CODE
    |     MODEL_YEAR, MAKE_CODE, MODEL_CODE
    |     ON_HAND_COUNT, IN_TRANSIT_COUNT, ON_HOLD_COUNT
    |     TOTAL_VALUE, AVG_DAYS_IN_STOCK
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT snapshot summary] --> [Terminal]
```

### Stock Summary Dashboard (STKSUM00)

```
[IMS Terminal]
    |
    | (Dealer Code)
    v
[STKSUM00] --GU--> [IO PCB]
    |
    [CURSOR] --> [STOCK_POSITION]
                    JOIN [MODEL_MASTER]
                    JOIN [PRICE_MASTER]
    |   (GROUP BY BODY_STYLE)
    |
    [Aggregate by body style:]
    |   Body Style | Count | Value      | Avg Days
    |   ---------- | ----- | ---------- | --------
    |   Sedan (SD) | 45    | $1,350,000 | 28
    |   SUV (SV)   | 32    | $1,280,000 | 35
    |   Truck (TK) | 18    | $720,000   | 42
    |   ...
    |
    [Grand totals:]
    |   Total inventory count
    |   Total estimated value (invoice basis)
    |   Average days in stock (from VEHICLE table)
    |
    [ISRT dashboard display] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

## Field-Level Data Mapping

| Source Field (COBOL)           | Table.Column                      | Format          | Validation Rules                       |
|-------------------------------|-----------------------------------|-----------------|----------------------------------------|
| WS-IN-VIN                     | STOCK_ADJUSTMENT.VIN              | X(17)           | Must exist in VEHICLE                  |
| WS-IN-ADJUST-TYPE             | STOCK_ADJUSTMENT.ADJUST_TYPE      | X(02)           | DM/WO/RC/PH/OT                        |
| WS-IN-ADJUST-REASON           | STOCK_ADJUSTMENT.ADJUST_REASON    | X(100)          | Required                               |
| WS-IN-DEALER-CODE             | STOCK_POSITION.DEALER_CODE        | X(05)           | Required for all inquiries             |
| (calculated)                  | STOCK_POSITION.ON_HAND_COUNT      | SMALLINT        | Updated by COMSTCK0                    |
| (calculated)                  | STOCK_POSITION.ON_HOLD_COUNT      | SMALLINT        | Updated on hold/release                |
| (calculated)                  | STOCK_POSITION.SOLD_MTD           | SMALLINT        | Incremented on sale                    |
| (calculated)                  | STOCK_POSITION.SOLD_YTD           | SMALLINT        | Incremented on sale                    |
| (calculated)                  | STOCK_SNAPSHOT.TOTAL_VALUE        | DEC(13,2)       | count * invoice price                  |
| (calculated)                  | STOCK_SNAPSHOT.AVG_DAYS_IN_STOCK  | SMALLINT        | AVG from VEHICLE.DAYS_IN_STOCK         |

## Error Paths

- **STKADJT0**: VIN not found returns error. Invalid adjustment type rejected. Status transition validated (e.g., cannot WO an already sold vehicle).
- **STKAGIN0**: No vehicles at dealer returns "NO INVENTORY FOR DEALER". PRICE_MASTER lookup failure uses zero value with warning.
- **STKALRT0**: No low-stock models returns "ALL MODELS ABOVE REORDER POINT". Display-only, no DB errors on write.
- **STKHLD00**: Cannot hold vehicle not in AV status. Cannot release vehicle not in HD status.
- **STKINQ00**: No stock positions for dealer/filters returns empty result.
- **STKRCN00**: Variance acceptance creates adjustment records; DB2 error on any insert rolls back all for that model.
- **STKSNAP0**: Duplicate snapshot for same date/dealer handled by DELETE-then-INSERT. Missing PRICE_MASTER data uses zero value.
- **STKSUM00**: Display-only; empty inventory returns "NO STOCK POSITIONS FOR DEALER".

## Cross-Domain Dependencies

| Dependency Direction       | Related Domain        | Data Exchanged                                          |
|---------------------------|-----------------------|---------------------------------------------------------|
| Stock <-- Vehicle         | COMSTCK0 called by VEHRCV00, VEHTRN00, VEHUPD00 to update counts |
| Stock <-- Sales           | SALCMP00/SALCAN00 update stock via COMSTCK0              |
| Stock <-- Production      | PLIDLVR0 triggers stock update on delivery               |
| Stock --> Floor Plan      | Aging data correlates with floor plan curtailment        |
| Stock <-- Admin           | MODEL_MASTER for descriptions; PRICE_MASTER for valuations |
