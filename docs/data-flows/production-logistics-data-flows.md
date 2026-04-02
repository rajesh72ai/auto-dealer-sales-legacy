# Production & Logistics Domain -- Data Flows

## Overview

The Production & Logistics domain manages the vehicle supply chain from factory to dealer lot. It covers production completion recording, dealer allocation, shipment creation, transit status tracking (including EDI 214 carrier feeds), delivery confirmation, production-to-stock reconciliation, and pre-delivery inspection (PDI) scheduling. This is the upstream domain that feeds vehicles into the dealer's inventory.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| PLIALLO0 | Allocation Engine                    | PLAL            |
| PLIDLVR0 | Delivery Confirmation                | PLDL            |
| PLIETA00 | ETA Tracking Screen                  | PLET            |
| PLIPROD0 | Production Completion                | PLPR            |
| PLIRECON | Prod-to-Stock Reconciliation         | PLRC            |
| PLISHPN0 | Shipment Creation                    | PLSH            |
| PLITRNS0 | Transit Status Update                | PLTR            |
| PLIVPDS0 | PDI Scheduling                       | PLPD            |

## Data Stores

| Table/Database                | Type | Key Fields                   | Used By                                       |
|-------------------------------|------|------------------------------|-----------------------------------------------|
| AUTOSALE.PRODUCTION_ORDER     | DB2  | PRODUCTION_ID (CHAR 12)      | PLIPROD0, PLIALLO0, PLIRECON                  |
| AUTOSALE.VEHICLE              | DB2  | VIN (CHAR 17)                | All PLI programs                              |
| AUTOSALE.VEHICLE_OPTION       | DB2  | VIN, OPTION_CODE             | PLIPROD0                                      |
| AUTOSALE.SHIPMENT             | DB2  | SHIPMENT_ID (CHAR 12)        | PLISHPN0, PLITRNS0, PLIDLVR0, PLIETA00, PLIRECON |
| AUTOSALE.SHIPMENT_VEHICLE     | DB2  | SHIPMENT_ID, VIN             | PLISHPN0, PLIDLVR0, PLIETA00, PLIRECON       |
| AUTOSALE.TRANSIT_STATUS       | DB2  | VIN, STATUS_SEQ              | PLITRNS0, PLIETA00                            |
| AUTOSALE.PDI_SCHEDULE         | DB2  | PDI_ID (auto-gen)            | PLIVPDS0, PLIDLVR0                            |
| AUTOSALE.DEALER               | DB2  | DEALER_CODE                  | PLIALLO0                                      |
| AUTOSALE.SYSTEM_CONFIG        | DB2  | CONFIG_KEY                   | PLIALLO0 (allocation priority)                |
| AUTOSALE.STOCK_POSITION       | DB2  | DEALER/YEAR/MAKE/MODEL       | PLIALLO0                                      |

## Data Flow Diagrams

### End-to-End Vehicle Supply Chain

```
[Manufacturer Plant]
    |
    v
[PLIPROD0] --> [PRODUCTION_ORDER] + [VEHICLE] (STATUS=PR)
    |             + [VEHICLE_OPTION]
    v
[PLIALLO0] --> [PRODUCTION_ORDER].ALLOCATED_DEALER
    |           [VEHICLE].DEALER_CODE, STATUS=AL
    v
[PLISHPN0] --> [SHIPMENT] + [SHIPMENT_VEHICLE]
    |           [VEHICLE] STATUS=SH (Shipped)
    v
[PLITRNS0] --> [TRANSIT_STATUS] (carrier updates)
    |           [SHIPMENT].SHIPMENT_STATUS
    |           [VEHICLE] STATUS=IT (In Transit)
    v
[PLIDLVR0] --> [VEHICLE] STATUS=DL (Delivered)
    |           [SHIPMENT] ACT_ARRIVAL, STATUS=DL
    |           [PDI_SCHEDULE] (auto-created)
    v
[PLIVPDS0] --> [PDI_SCHEDULE] STATUS updates
    |           [VEHICLE].PDI_COMPLETE=Y
    v
[Vehicle Available for Sale] STATUS=AV
```

### Production Completion Flow (PLIPROD0)

```
[Plant Production Feed / IMS Terminal]
    |
    | PLPR transaction (VIN, Year/Make/Model, Plant, Build Date, Options)
    v
[PLIPROD0] --GU--> [IO PCB]
    |
    [CALL COMVALD0] (validate VIN checksum)
    [CALL COMVINL0] (decode VIN: year, make, model)
    |
    [Check for duplicate VIN in VEHICLE table]
    |
    [INSERT] --> [PRODUCTION_ORDER]
    |   PRODUCTION_ID = generated
    |   VIN, MODEL_YEAR, MAKE_CODE, MODEL_CODE
    |   PLANT_CODE, BUILD_DATE
    |   BUILD_STATUS = 'CM' (Complete)
    |
    [INSERT] --> [VEHICLE]
    |   VIN, MODEL_YEAR, MAKE_CODE, MODEL_CODE
    |   EXTERIOR_COLOR, INTERIOR_COLOR
    |   PRODUCTION_DATE = BUILD_DATE
    |   VEHICLE_STATUS = 'PR' (Produced)
    |
    [For each option in feed:]
    |   [INSERT] --> [VEHICLE_OPTION]
    |     VIN, OPTION_CODE, OPTION_DESC, OPTION_PRICE
    |     INSTALLED_FLAG = 'F' (Factory)
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT production confirmation] --> [Terminal]
```

### Allocation Engine (PLIALLO0)

```
[IMS Terminal]
    |
    | PLAL transaction (VIN or auto-allocate by model)
    v
[PLIALLO0] --GU--> [IO PCB]
    |
    |-- Single VIN mode --------+
    |                            |
    |   [SELECT] --> [PRODUCTION_ORDER] (STATUS=CM, no allocated dealer)
    |   [SELECT] --> [VEHICLE] (STATUS=PR)
    |
    |-- Auto-allocate mode -----+
    |                            |
    |   [CURSOR] --> [PRODUCTION_ORDER] (unallocated for model)
    |
    [For each vehicle to allocate:]
    |
    |   [SELECT] --> [SYSTEM_CONFIG] (allocation priority rules)
    |   [SELECT] --> [DEALER] (region matching, verify active)
    |   [SELECT] --> [STOCK_POSITION] (check vs MAX_INVENTORY)
    |
    |   [Priority logic:]
    |     1. Region match (same region as plant)
    |     2. Lowest current inventory vs max
    |     3. Dealer priority ranking from config
    |
    |   [UPDATE] --> [PRODUCTION_ORDER]
    |     ALLOCATED_DEALER = selected dealer
    |     ALLOCATION_DATE = current date
    |
    |   [UPDATE] --> [VEHICLE]
    |     DEALER_CODE = allocated dealer
    |     VEHICLE_STATUS = 'AL' (Allocated)
    |
    |   [CALL COMSTCK0 ALOC] --> [STOCK_POSITION]
    |     ALLOCATED_COUNT + 1
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT allocation results] --> [Terminal]
```

### Shipment Creation (PLISHPN0)

```
[IMS Terminal]
    |
    | PLSH transaction (Carrier, Origin, Dest Dealer, Transport Mode, VINs)
    v
[PLISHPN0] --GU--> [IO PCB]
    |
    [CALL COMSEQL0] (generate SHIPMENT_ID)
    |
    [INSERT] --> [SHIPMENT]
    |   CARRIER_CODE, ORIGIN_PLANT, DEST_DEALER
    |   TRANSPORT_MODE (RL/TK/SH/ML)
    |   SHIP_DATE = current
    |   EST_ARRIVAL = calculated based on mode:
    |     Rail: +7 days, Truck: +3 days
    |     Ship: +14 days, Multi-Leg: +10 days
    |   STATUS = 'DP' (Dispatched)
    |
    [For each VIN in load:]
    |
    |   [SELECT] --> [VEHICLE] (verify STATUS=AL)
    |
    |   [INSERT] --> [SHIPMENT_VEHICLE]
    |     SHIPMENT_ID, VIN, LOAD_SEQUENCE
    |
    |   [UPDATE] --> [VEHICLE]
    |     VEHICLE_STATUS = 'SH' (Shipped)
    |     SHIP_DATE = current
    |
    |   VEHICLE_COUNT + 1
    |
    [UPDATE SHIPMENT] VEHICLE_COUNT = total loaded
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT shipment confirmation] --> [Terminal]
```

### Transit Status Update (PLITRNS0)

```
[EDI 214 Feed / IMS Terminal]
    |
    | PLTR transaction (VIN, Status, Location, EDI Ref)
    v
[PLITRNS0] --GU--> [IO PCB]
    |
    [If EDI format: CALL COMEDIL0 to parse]
    |
    [SELECT] --> [VEHICLE] (get current state)
    [SELECT] --> [SHIPMENT] (via SHIPMENT_VEHICLE lookup)
    |
    [Validate status sequence:]
    |   DP (Departed) -> AR (Arrived) -> TF (Transferred)
    |   -> DL (Delivered) | DY (Delayed)
    |
    [INSERT] --> [TRANSIT_STATUS]
    |   VIN, STATUS_SEQ (next in sequence)
    |   LOCATION_DESC, STATUS_CODE
    |   EDI_REF_NUM, STATUS_TS
    |
    [UPDATE] --> [SHIPMENT]
    |   SHIPMENT_STATUS = latest status
    |
    [UPDATE] --> [VEHICLE]
    |   VEHICLE_STATUS = 'IT' (In Transit)
    |
    [If STATUS = DL (Delivered):]
    |   --> Trigger PLIDLVR0 delivery confirmation
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT transit update confirmation] --> [Terminal]
```

### Delivery Confirmation (PLIDLVR0)

```
[IMS Terminal]
    |
    | PLDL transaction (VIN or Shipment ID, Damage, Odometer)
    v
[PLIDLVR0] --GU--> [IO PCB]
    |
    [CALL COMVALD0] (validate VIN)
    |
    [SELECT] --> [VEHICLE]
    [SELECT] --> [SHIPMENT_VEHICLE] (find shipment)
    [SELECT] --> [SHIPMENT]
    |
    [UPDATE] --> [VEHICLE]
    |   VEHICLE_STATUS = 'DL' (Delivered)
    |   RECEIVE_DATE = current date
    |   ODOMETER = input
    |   DAMAGE_FLAG / DAMAGE_DESC if applicable
    |
    [Check if all VINs in shipment delivered:]
    |   [SELECT COUNT] --> [SHIPMENT_VEHICLE]
    |     WHERE not yet delivered
    |   IF count = 0:
    |     [UPDATE] --> [SHIPMENT]
    |       ACT_ARRIVAL_DATE = current date
    |       SHIPMENT_STATUS = 'DL'
    |
    [CALL COMSTCK0 RECV] --> [STOCK_POSITION]
    |   ON_HAND_COUNT + 1
    |
    [INSERT] --> [PDI_SCHEDULE]
    |   VIN, DEALER_CODE, SCHEDULED_DATE
    |   PDI_STATUS = 'SC' (Scheduled)
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT delivery confirmation] --> [Terminal]
```

### PDI Scheduling (PLIVPDS0)

```
[IMS Terminal]
    |
    | PLPD transaction (VIN, Scheduled Date, Technician, Action)
    v
[PLIVPDS0] --GU--> [IO PCB]
    |
    |-- FUNC=SC (Schedule) ----+
    |                           |
    |   [INSERT/UPDATE] --> [PDI_SCHEDULE]
    |     VIN, SCHEDULED_DATE, TECHNICIAN_ID
    |     PDI_STATUS = 'SC'
    |
    |-- FUNC=IP (In Progress) -+
    |                           |
    |   [UPDATE] --> [PDI_SCHEDULE] STATUS = 'IP'
    |
    |-- FUNC=CM (Complete) ----+
    |                           |
    |   [UPDATE] --> [PDI_SCHEDULE]
    |     STATUS = 'CM', COMPLETED_TS
    |     ITEMS_PASSED, ITEMS_FAILED
    |   [UPDATE] --> [VEHICLE]
    |     PDI_COMPLETE = 'Y'
    |     PDI_DATE = current date
    |     VEHICLE_STATUS = 'AV' (Available for sale)
    |
    |-- FUNC=FL (Failed) ------+
    |                           |
    |   [UPDATE] --> [PDI_SCHEDULE]
    |     STATUS = 'FL', NOTES = failure details
    |   [Requires reschedule before vehicle available]
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT PDI status] --> [Terminal]
```

### ETA Tracking (PLIETA00)

```
[IMS Terminal]
    |
    | PLET transaction (VIN, Dealer Code, or Shipment ID)
    v
[PLIETA00] --GU--> [IO PCB]
    |
    [SELECT] --> [SHIPMENT] + [SHIPMENT_VEHICLE] + [VEHICLE]
    |
    [CURSOR] --> [TRANSIT_STATUS] (by VIN, ordered by SEQ)
    |
    [Display timeline:]
    |   Date/Time   | Location         | Status
    |   ----------- | ---------------- | ------
    |   2026-03-15  | Plant Assembly   | DP (Departed)
    |   2026-03-17  | Chicago Rail Hub | AR (Arrived)
    |   2026-03-18  | Chicago Rail Hub | DP (Departed)
    |   2026-03-20  | Dallas Terminal  | AR (Arrived)
    |
    [CALL COMDTEL0] (calculate days in transit)
    |   Days in transit = current - SHIP_DATE
    |   Est days remaining = EST_ARRIVAL - current
    |
    [ISRT ETA display] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

### Production-to-Stock Reconciliation (PLIRECON)

```
[IMS Terminal]
    |
    | PLRC transaction
    v
[PLIRECON] --GU--> [IO PCB]
    |
    [Multi-table query:]
    |
    |   [Produced but not in VEHICLE:]
    |     PRODUCTION_ORDER LEFT JOIN VEHICLE
    |     WHERE VEHICLE.VIN IS NULL
    |
    |   [Allocated but not shipped:]
    |     PRODUCTION_ORDER WHERE ALLOCATED_DEALER IS NOT NULL
    |     AND VIN NOT IN (SHIPMENT_VEHICLE)
    |
    |   [Shipped but not delivered:]
    |     SHIPMENT_VEHICLE JOIN VEHICLE
    |     WHERE VEHICLE.VEHICLE_STATUS IN ('SH','IT')
    |     AND SHIPMENT.SHIPMENT_STATUS != 'DL'
    |
    [Exception list with reason codes]
    |
    [Summary:]
    |   Total Produced:   XXX
    |   Total Allocated:  XXX
    |   Total Shipped:    XXX
    |   Total Delivered:  XXX
    |   Exceptions:       XXX
    |
    [ISRT reconciliation display] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

## Field-Level Data Mapping

| Source Field (COBOL)         | Table.Column                      | Format          | Validation Rules                        |
|-----------------------------|-----------------------------------|-----------------|-----------------------------------------|
| WS-IN-VIN                   | PRODUCTION_ORDER.VIN              | X(17)           | Validated via COMVALD0                  |
| WS-IN-PLANT-CODE            | PRODUCTION_ORDER.PLANT_CODE       | X(04)           | Required                                |
| WS-IN-BUILD-DATE            | PRODUCTION_ORDER.BUILD_DATE       | X(10)->DATE     | YYYY-MM-DD                              |
| WS-IN-CARRIER-CODE          | SHIPMENT.CARRIER_CODE             | X(05)           | Required                                |
| WS-IN-TRANSPORT-MODE        | SHIPMENT.TRANSPORT_MODE           | X(02)           | RL/TK/SH/ML                             |
| WS-IN-STATUS-CODE           | TRANSIT_STATUS.STATUS_CODE        | X(02)           | DP/AR/TF/DL/DY                          |
| WS-IN-LOCATION-DESC         | TRANSIT_STATUS.LOCATION_DESC      | X(60)           | Required                                |
| WS-IN-EDI-REF               | TRANSIT_STATUS.EDI_REF_NUM        | X(20)           | Optional, from EDI 214                  |
| WS-IN-SCHEDULED-DATE        | PDI_SCHEDULE.SCHEDULED_DATE       | X(10)->DATE     | Must be >= today                        |
| WS-IN-TECHNICIAN            | PDI_SCHEDULE.TECHNICIAN_ID        | X(08)           | Must exist in SYSTEM_USER               |

## Error Paths

- **PLIPROD0**: Duplicate VIN returns "VIN ALREADY EXISTS". Invalid VIN checksum rejected. Missing required fields (year/make/model) rejected.
- **PLIALLO0**: Vehicle not in PR status returns error. Dealer at max inventory returns "DEALER AT CAPACITY". No eligible dealer found returns "NO DEALER AVAILABLE FOR ALLOCATION".
- **PLISHPN0**: Vehicle not in AL status cannot be shipped. COMSEQL0 failure prevents shipment creation.
- **PLITRNS0**: Out-of-sequence status update rejected. Shipment not found returns error. EDI parse failure (COMEDIL0) returns format error.
- **PLIDLVR0**: Vehicle not in SH/IT status cannot be delivered. VIN not in expected shipment returns "VIN NOT IN SHIPMENT".
- **PLIVPDS0**: PDI failure (STATUS=FL) blocks vehicle from becoming available until rescheduled and completed.
- **PLIRECON/PLIETA00**: Display-only; no write errors. Empty results return appropriate "NO DATA" messages.

## Cross-Domain Dependencies

| Dependency Direction         | Related Domain       | Data Exchanged                                          |
|-----------------------------|----------------------|---------------------------------------------------------|
| Production --> Vehicle      | PLIPROD0 creates VEHICLE records; PLIDLVR0 updates status |
| Production --> Stock        | PLIDLVR0 triggers COMSTCK0 for stock position updates    |
| Production <-- Admin        | DEALER for allocation; SYSTEM_CONFIG for priority rules  |
| Production --> Vehicle      | PLIALLO0 updates VEHICLE.DEALER_CODE                     |
| Production --> Vehicle      | PLIVPDS0 updates VEHICLE.PDI_COMPLETE and status         |
| Production <-- EDI          | PLITRNS0 receives EDI 214 carrier status feeds           |
