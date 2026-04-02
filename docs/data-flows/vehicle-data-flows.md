# Vehicle Lifecycle Domain -- Data Flows

## Overview

The Vehicle Lifecycle domain manages individual vehicle records from the moment they arrive at the dealership through their operational life on the lot. It covers vehicle inquiry, receiving/check-in, lot location management, inventory listing, aging analysis, allocation from manufacturer, inter-dealer transfers, and manual status updates. This domain is the physical inventory backbone of AUTOSALES.

## Programs in This Domain

| Program  | Description                          | Transaction Code |
|----------|--------------------------------------|-----------------|
| VEHAGE00 | Inventory Aging Display              | VHAG            |
| VEHALL00 | Vehicle Allocation from Manufacturer | VHAL            |
| VEHINQ00 | Vehicle Inquiry (VIN/Stock#)         | VHIQ            |
| VEHLOC00 | Lot Location Management              | VHLC            |
| VEHLST00 | Inventory Listing (Dealer/Model)     | VHLS            |
| VEHRCV00 | Vehicle Receiving / Check-In         | VHRC            |
| VEHTRN00 | Dealer-to-Dealer Transfer            | VHTR            |
| VEHUPD00 | Vehicle Status Update                | VHUP            |

## Data Stores

| Table/Database                | Type | Key Fields                   | Used By                                      |
|-------------------------------|------|------------------------------|----------------------------------------------|
| AUTOSALE.VEHICLE              | DB2  | VIN (CHAR 17)                | All VEH programs                             |
| AUTOSALE.VEHICLE_OPTION       | DB2  | VIN, OPTION_CODE             | VEHINQ00                                     |
| AUTOSALE.VEHICLE_STATUS_HIST  | DB2  | VIN, STATUS_SEQ              | VEHINQ00, VEHALL00, VEHRCV00, VEHTRN00, VEHUPD00 |
| AUTOSALE.MODEL_MASTER         | DB2  | YEAR/MAKE/MODEL              | VEHINQ00, VEHLST00                           |
| AUTOSALE.LOT_LOCATION         | DB2  | DEALER_CODE, LOCATION_CODE   | VEHLOC00                                     |
| AUTOSALE.PDI_SCHEDULE         | DB2  | PDI_ID (auto-gen)            | VEHRCV00                                     |
| AUTOSALE.STOCK_TRANSFER       | DB2  | TRANSFER_ID (auto-gen)       | VEHTRN00                                     |
| AUTOSALE.PRODUCTION_ORDER     | DB2  | PRODUCTION_ID (CHAR 12)      | VEHALL00                                     |
| AUTOSALE.PRICE_SCHEDULE       | DB2  | YEAR/MAKE/MODEL/TYPE/DATE    | VEHAGE00                                     |
| AUTOSALE.DEALER               | DB2  | DEALER_CODE                  | VEHALL00                                     |

## Data Flow Diagrams

### Vehicle Receiving / Check-In Flow (VEHRCV00)

```
[Delivery Truck Arrives]
    |
    | VHRC transaction (VIN scan, Stock#, Location, Odometer)
    v
[VEHRCV00] --GU--> [IO PCB]
    |
    [CALL COMVALD0] (validate VIN checksum)
    [CALL COMVINL0] (decode VIN: year, make, model)
    |
    [SELECT] --> [VEHICLE] (verify expected at this dealer)
    |   Must be STATUS = IT (In Transit) or SH (Shipped)
    |
    [Capture receiving data:]
    |   Stock number (auto via COMSEQL0 or manual)
    |   Lot location
    |   Odometer reading
    |   Damage inspection (flag + description)
    |   Key number
    |
    [UPDATE] --> [VEHICLE]
    |   STATUS = 'DL' then 'AV' (Delivered -> Available)
    |   RECEIVE_DATE = current date
    |   STOCK_NUMBER, LOT_LOCATION, ODOMETER
    |   DAMAGE_FLAG, DAMAGE_DESC, KEY_NUMBER
    |
    [INSERT] --> [VEHICLE_STATUS_HIST]
    |   (old status -> new status, reason, user)
    |
    [CALL COMSTCK0 RECV] --> [STOCK_POSITION]
    |   ON_HAND_COUNT + 1
    |
    [INSERT] --> [PDI_SCHEDULE]
    |   (schedule pre-delivery inspection)
    |   STATUS = 'SC', SCHEDULED_DATE = receive + 1 day
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT receiving confirmation] --> [Terminal]
```

### Vehicle Inquiry Flow (VEHINQ00)

```
[IMS Terminal]
    |
    | VHIQ transaction (VIN or Stock Number)
    v
[VEHINQ00] --GU--> [IO PCB]
    |
    [SELECT] --> [VEHICLE] JOIN [MODEL_MASTER]
    |   (by VIN or STOCK_NUMBER)
    |
    [Display vehicle details:]
    |   VIN, Stock#, Year, Make, Model, Body, Trim
    |   Color (ext/int), Engine, Trans, Drivetrain
    |   Status, Dealer, Location, Days in Stock
    |   PDI complete, Damage flag, Odometer
    |
    [CURSOR] --> [VEHICLE_OPTION]
    |   (all options for this VIN)
    |   Option code, description, price, installed type
    |
    [CURSOR] --> [VEHICLE_STATUS_HIST]
    |   (chronological status changes)
    |   Old status -> New status, Changed by, Timestamp
    |
    [CALL COMVINL0] (VIN decode display)
    [CALL COMFMTL0] (format currency fields)
    |
    [ISRT detail display] --> [Terminal]
    (DISPLAY ONLY - no updates)
```

### Vehicle Allocation Flow (VEHALL00)

```
[IMS Terminal / PLIPROD0]
    |
    | VHAL transaction (VIN, Dealer Code)
    v
[VEHALL00] --GU--> [IO PCB]
    |
    [CALL COMVALD0] (validate VIN)
    |
    [SELECT] --> [PRODUCTION_ORDER] (verify produced, not yet allocated)
    [SELECT] --> [VEHICLE]          (verify STATUS = PR)
    [SELECT] --> [DEALER]           (verify dealer exists, capacity)
    |
    [UPDATE] --> [PRODUCTION_ORDER]
    |   ALLOCATED_DEALER = dealer code
    |   ALLOCATION_DATE = current date
    |
    [UPDATE] --> [VEHICLE]
    |   DEALER_CODE = allocated dealer
    |   VEHICLE_STATUS = 'AL' (Allocated)
    |
    [INSERT] --> [VEHICLE_STATUS_HIST]
    |   (PR -> AL, allocation reason)
    |
    [CALL COMSTCK0 ALOC] --> [STOCK_POSITION]
    |   ALLOCATED_COUNT + 1
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT allocation confirmation] --> [Terminal]
```

### Inter-Dealer Transfer Flow (VEHTRN00)

```
[IMS Terminal]
    |
    | VHTR transaction
    v
[VEHTRN00] --GU--> [IO PCB]
    |
    |-- FUNC=RQ (Request) -----+
    |                           |
    |   [SELECT] --> [VEHICLE] (must be AV, not HD, not in deal)
    |   [INSERT] --> [STOCK_TRANSFER]
    |     FROM_DEALER, TO_DEALER, VIN
    |     STATUS = 'RQ' (Requested)
    |
    |-- FUNC=AP (Approve) -----+
    |                           |
    |   [SELECT] --> [STOCK_TRANSFER] (must be RQ)
    |   [UPDATE] --> [STOCK_TRANSFER] STATUS = 'AP'
    |   [UPDATE] --> [VEHICLE]
    |     DEALER_CODE = TO_DEALER
    |     STATUS = 'TR' (Transfer)
    |   [INSERT] --> [VEHICLE_STATUS_HIST]
    |   [CALL COMSTCK0 TRNO] --> [STOCK_POSITION] (FROM dealer -1)
    |
    |-- FUNC=RJ (Reject) ------+
    |                           |
    |   [UPDATE] --> [STOCK_TRANSFER] STATUS = 'RJ'
    |
    |-- FUNC=CM (Complete) ----+
    |                           |
    |   [UPDATE] --> [STOCK_TRANSFER] STATUS = 'CM'
    |   [UPDATE] --> [VEHICLE] STATUS = 'AV'
    |   [CALL COMSTCK0 TRNI] --> [STOCK_POSITION] (TO dealer +1)
    |   [INSERT] --> [VEHICLE_STATUS_HIST]
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT transfer status] --> [Terminal]
```

### Lot Location Management (VEHLOC00)

```
[IMS Terminal]
    |
    | VHLC transaction
    v
[VEHLOC00] --GU--> [IO PCB]
    |
    |-- FUNC=INQ --CURSOR---> [LOT_LOCATION] (list for dealer)
    |                          (code, desc, type, capacity, count)
    |
    |-- FUNC=ADD --INSERT---> [LOT_LOCATION]
    |              (S=Showroom, F=Front, B=Back, O=Offsite, R=Recon)
    |
    |-- FUNC=UPD --UPDATE---> [LOT_LOCATION]
    |
    |-- FUNC=ASGN (Assign vehicle to location) ---+
    |                                               |
    |   [SELECT] --> [LOT_LOCATION] (check capacity)
    |   IF CURRENT_COUNT >= MAX_CAPACITY --> error
    |   [UPDATE] --> [VEHICLE] (LOT_LOCATION = new)
    |   [UPDATE] --> [LOT_LOCATION]
    |     old location: CURRENT_COUNT - 1
    |     new location: CURRENT_COUNT + 1
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
```

### Vehicle Status Update (VEHUPD00)

```
[IMS Terminal]
    |
    | VHUP transaction (VIN, New Status, Reason)
    v
[VEHUPD00] --GU--> [IO PCB]
    |
    [SELECT] --> [VEHICLE] (get current status)
    |
    [Validate status transition:]
    |   PR -> AL (allocation only)
    |   AL -> SH/IT (shipping)
    |   IT -> DL (delivery)
    |   DL -> AV (available after PDI)
    |   AV -> HD/SD/TR (hold, sold, transfer)
    |   HD -> AV (release)
    |   SD -> AV (ONLY via SALCAN00 unwind)
    |   Invalid transitions rejected
    |
    [UPDATE] --> [VEHICLE] (VEHICLE_STATUS = new status)
    |
    [INSERT] --> [VEHICLE_STATUS_HIST]
    |   (old, new, changed_by, reason, timestamp)
    |
    [CALL COMSTCK0] --> [STOCK_POSITION] (appropriate function)
    |
    [CALL COMLGEL0] --> [AUDIT_LOG]
    [ISRT status update confirmation] --> [Terminal]
```

## Field-Level Data Mapping

| Source Field (COBOL)         | Table.Column                   | Format           | Validation Rules                          |
|-----------------------------|--------------------------------|-------------------|-------------------------------------------|
| WS-IN-VIN / WS-RC-VIN      | VEHICLE.VIN                    | X(17)             | Validated via COMVALD0 checksum           |
| WS-RC-STOCK-NUM             | VEHICLE.STOCK_NUMBER           | X(08)             | Auto or manual; unique per dealer         |
| WS-RC-LOT-LOCATION          | VEHICLE.LOT_LOCATION           | X(06)             | Must exist in LOT_LOCATION                |
| WS-RC-ODOMETER              | VEHICLE.ODOMETER               | 9(06) -> INT      | Must be >= 0                              |
| WS-RC-DAMAGE-FLAG           | VEHICLE.DAMAGE_FLAG            | X(01)             | Y/N                                       |
| WS-RC-DAMAGE-DESC           | VEHICLE.DAMAGE_DESC            | X(200)            | Required if DAMAGE_FLAG=Y                 |
| WS-RC-KEY-NUMBER            | VEHICLE.KEY_NUMBER             | X(06)             | Optional                                  |
| WS-UP-NEW-STATUS            | VEHICLE.VEHICLE_STATUS         | X(02)             | PR/AL/SH/IT/DL/AV/HD/SD/TR               |
| WS-UP-REASON                | VEHICLE_STATUS_HIST.CHANGE_REASON | X(60)          | Required for status changes               |
| WS-TR-FROM-DEALER           | STOCK_TRANSFER.FROM_DEALER     | X(05)             | Must exist in DEALER                      |
| WS-TR-TO-DEALER             | STOCK_TRANSFER.TO_DEALER       | X(05)             | Must exist, different from FROM           |

## Error Paths

- **VEHRCV00**: VIN fails checksum returns "INVALID VIN". Vehicle not expected at this dealer returns "VEHICLE NOT ASSIGNED TO THIS DEALER". Vehicle not in IT/SH status returns "VEHICLE NOT IN TRANSIT".
- **VEHINQ00**: VIN/Stock# not found returns "VEHICLE NOT FOUND". Display-only, no write errors possible.
- **VEHALL00**: Vehicle not in PR status returns error. Dealer at max capacity returns "DEALER INVENTORY AT MAXIMUM".
- **VEHLOC00**: Location at max capacity returns "LOCATION FULL". Vehicle not at this dealer rejected.
- **VEHLST00**: No vehicles matching filters returns "NO VEHICLES FOUND".
- **VEHTRN00**: Vehicle on hold, in a deal, or already sold cannot be transferred. Transfer to same dealer rejected. Only manager can approve.
- **VEHUPD00**: Invalid status transitions rejected with specific message (e.g., "CANNOT CHANGE FROM SD TO AV - USE DEAL UNWIND"). Must provide reason for all changes.
- **VEHAGE00**: No vehicles at dealer returns "NO INVENTORY FOR DEALER".

## Cross-Domain Dependencies

| Dependency Direction        | Related Domain          | Data Exchanged                                       |
|----------------------------|-------------------------|------------------------------------------------------|
| Vehicle <-- Production     | PLIALLO0/PLIPROD0 create VEHICLE and PRODUCTION_ORDER records |
| Vehicle <-- Production     | PLIDLVR0 triggers receiving flow                     |
| Vehicle --> Sales          | SALQOT00 reads VEHICLE for deal creation; SALCMP00 updates status to SD |
| Vehicle --> Stock          | VEHRCV00, VEHTRN00, VEHUPD00 all update STOCK_POSITION via COMSTCK0 |
| Vehicle --> Floor Plan     | Floor plan keyed by VIN; receiving triggers FPLADD00 |
| Vehicle <-- Admin          | MODEL_MASTER for descriptions; SYSTEM_CONFIG for sequences |
| Vehicle --> Warranty       | WARRANTY keyed by VIN; WRCINQ00 reads vehicle data   |
| Vehicle --> Registration   | REGISTRATION keyed by VIN                            |
