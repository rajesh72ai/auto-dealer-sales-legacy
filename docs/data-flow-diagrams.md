# AUTOSALES Data Flow Diagrams

## 1. Deal Lifecycle Flow

```
                          CUSTOMER                    SALESPERSON
                             |                            |
                             v                            v
                    +------------------+        +------------------+
                    | Customer Search  |        | Vehicle Search   |
                    | (CUSINQ00)       |------->| (VEHINQ00)       |
                    +------------------+        +------------------+
                             |                            |
                             +--------+    +--------------+
                                      |    |
                                      v    v
                              +------------------+
                              |  DEAL WORKSHEET  |
                              |  (SALQOT00)      |
                              |  Status: WS      |
                              +------------------+
                                      |
                    +-----------------+------------------+
                    |                 |                   |
                    v                 v                   v
           +-------------+  +----------------+  +----------------+
           | Trade-In    |  | Incentives     |  | Tax Calc       |
           | (SALTRD00)  |  | (SALINC00)     |  | (COMTAXL0)     |
           +-------------+  +----------------+  +----------------+
                    |                 |                   |
                    +-----------------+-------------------+
                                      |
                                      v
                              +------------------+
                              |  NEGOTIATION     |
                              |  (SALNEG00)      |
                              |  Status: NE      |
                              +------------------+
                                      |
                                      v
                              +------------------+
                              |  VALIDATION      |
                              |  (SALVAL00)      |
                              |  Status: PA      |
                              +------------------+
                                      |
                                      v
                              +------------------+         +------------------+
                              |  APPROVAL        |-------->| REJECTION        |
                              |  (SALAPV00)      |         | Status: NE       |
                              |  Status: AP      |         | (back to negot.) |
                              +------------------+         +------------------+
                                      |
                                      v
                    +-----------------+------------------+
                    |                 |                   |
                    v                 v                   v
           +-------------+  +----------------+  +----------------+
           | Finance App |  | F&I Products   |  | Lease Calc     |
           | (FINAPP00)  |  | (FINPRD00)     |  | (FINLSE00)     |
           | Status: FI  |  |                |  |                |
           +-------------+  +----------------+  +----------------+
                    |                 |                   |
                    v                 v                   |
           +-------------+  +----------------+           |
           | Credit Check|  | Finance Docs   |<----------+
           | (FINCHK00)  |  | (FINDOC00)     |
           +-------------+  +----------------+
                    |                 |
                    v                 |
           +-------------+           |
           | Fin Approval|           |
           | (FINAPV00)  |           |
           +-------------+           |
                    |                 |
                    +-----------------+
                                      |
                                      v
                              +------------------+
                              |  DELIVERY        |
                              |  (SALCMP00)      |
                              |  Status: DL      |
                              +------------------+
                                      |
                    +-----------------+------------------+
                    |                                    |
                    v                                    v
           +----------------+                  +------------------+
           | Warranty Reg   |                  | Registration Gen |
           | (WRCWAR00)     |                  | (REGGEN00)       |
           +----------------+                  +------------------+


         At any point before DL:           After DL:
           +------------------+             +------------------+
           | CANCELLATION     |             | UNWIND           |
           | (SALCAN00)       |             | (SALCAN00)       |
           | Status: CA       |             | Status: UW       |
           +------------------+             +------------------+
```

## 2. Vehicle Lifecycle Flow

```
  MANUFACTURER                                            DEALER
  ==========                                              ======

  +------------------+
  | Production       |
  | Completion       |
  | (PLIPROD0)       |
  | Status: PR       |
  +------------------+
           |
           v
  +------------------+
  | Allocation       |
  | (PLIALLO0/       |
  |  VEHALL00)       |
  | Status: AL       |
  +------------------+
           |
           v
  +------------------+
  | Shipment         |
  | Creation         |
  | (PLISHPN0)       |
  | Status: SH       |
  +------------------+
           |
           v
  +------------------+     +------------------+
  | Transit Status   |---->| ETA Tracking     |
  | Updates          |     | (PLIETA00)       |
  | (PLITRNS0)       |     | (Display Only)   |
  | EDI 214 Feed     |     +------------------+
  +------------------+
           |
           | DP -> AR -> TF -> DL
           v
  +------------------+                      +------------------+
  | Delivery         |--------------------->| Vehicle Receiving|
  | Confirmation     |                      | Dock Check-In    |
  | (PLIDLVR0)       |                      | (VEHRCV00)       |
  | Status: DL       |                      | Status: AV       |
  +------------------+                      +------------------+
                                                     |
                                                     v
                                            +------------------+
                                            | PDI Scheduling   |
                                            | (PLIVPDS0)       |
                                            | SC->IP->CM/FL    |
                                            +------------------+
                                                     |
                              +----------------------+----------------------+
                              |                      |                      |
                              v                      v                      v
                     +-------------+        +-------------+        +-------------+
                     | On Hold     |        | For Sale     |        | Transfer    |
                     | (STKHLD00)  |        | (Available)  |        | (VEHTRN00)  |
                     | Status: HD  |        | Status: AV   |        | Status: TR  |
                     +-------------+        +-------------+        +-------------+
                              |                      |
                              v                      v
                     +-------------+        +------------------+
                     | Release     |        | SELL (SALCMP00)  |
                     | Status: AV  |        | Status: SD       |
                     +-------------+        +------------------+
```

## 3. Floor Plan Lifecycle

```
  VEHICLE RECEIVED                    DAILY BATCH                   VEHICLE SOLD
  ================                    ===========                   ============

  +------------------+
  | Floor Plan Add   |
  | (FPLADD00)       |
  | Balance = Invoice|
  | Status: AC       |
  +------------------+
           |
           |     +--------------------------------------------------+
           |     |                                                  |
           v     v                                                  |
  +------------------+                                              |
  |  Daily Interest  |<--- BATDLY00 (nightly batch)                 |
  |  Accrual         |                                              |
  |  (FPLINT00 /     |     +------------------+                     |
  |   COMINTL0)      |---->| FLOOR_PLAN_      |                     |
  |                  |     | INTEREST table   |                     |
  +------------------+     | (daily records)  |                     |
           |               +------------------+                     |
           |                                                        |
           |     +------------------+                               |
           +---->| Inquiry /        |                               |
           |     | Exposure Report  |                               |
           |     | (FPLINQ00 /      |                               |
           |     |  FPLRPT00)       |                               |
           |     +------------------+                               |
           |                                                        |
           |     +------------------+                               |
           |     | Curtailment      |                               |
           +---->| Warning          |  (within 15 days of limit)    |
           |     | New: 90 days     |                               |
           |     | Used: 60 days    |                               |
           |     +------------------+                               |
           |                                                        |
           v                                                        |
  +------------------+                                              |
  | Floor Plan       |<---------------------------------------------+
  | Payoff           |
  | (FPLPAY00)       |
  | Final interest   |
  | Status: PD       |
  +------------------+
```

## 4. Registration Flow

```
  DEAL DELIVERED (DL)
  ===================
           |
           v
  +------------------+
  | Registration     |
  | Document Gen     |
  | (REGGEN00)       |
  | Status: PR       |
  +------------------+
           |
           v
  +------------------+
  | Registration     |
  | Validation       |         NO
  | (REGVAL00)       |-------> [Errors returned, fix data]
  | Check: customer, |         Status stays PR
  | VIN, state, fees |
  +------------------+
           | YES
           v
  +------------------+
  | Status: VL       |
  | (Validated)      |
  +------------------+
           |
           v
  +------------------+
  | Registration     |
  | Submission       |         +------------------+
  | (REGSUB00)       |-------->| Tracking Number  |
  | Status: SB       |         | Generated        |
  +------------------+         +------------------+
           |
           v
  +------------------+
  | State DMV        |
  | Processing       |
  +------------------+
           |
     +-----+-----+
     |           |
     v           v
  +--------+  +--------+
  | ISSUED |  |REJECTED|
  | (IS)   |  | (RJ)   |
  +--------+  +--------+
     |           |
     v           v
  +--------+  +--------+
  | Plate# |  |Reason  |
  | Title# |  |logged  |
  | Date   |  |Can     |
  +--------+  |resubmit|
               +--------+
```

## 5. Batch Processing Flows

### Daily Processing (BATDLY00 + Integration Jobs)

```
  +=====================================================================+
  |                    DAILY NIGHTLY BATCH                               |
  +=====================================================================+

  BATDLY00 (End-of-Day Processing)
  ================================
  +------------------+     +------------------+     +------------------+
  | 1. Status Sync   |     | 2. Expire Aged   |     | 3. Floor Plan    |
  | Delivered deals  |     | Pending deals    |     | Interest Accrual |
  | -> Vehicle SOLD  |     | (30+ days old)   |     | All active FP    |
  +------------------+     +------------------+     | vehicles         |
                                                    +------------------+
                                                           |
                                                           v
                                                    +------------------+
                                                    | FLOOR_PLAN_      |
                                                    | INTEREST records |
                                                    +------------------+

  BATCRM00 (CRM Extract)        BATDMS00 (DMS Export)
  =======================        =====================
  +------------------+           +------------------+
  | Changed          |           | Active inventory |
  | customers        |           | + recent deals   |
  | since last run   |           |                  |
  +------------------+           +------------------+
           |                              |
           v                              v
  +------------------+           +------------------+
  | CRMFILE DD       |           | DMSFILE DD       |
  | Pipe-delimited   |           | Header + Detail  |
  +------------------+           +------------------+

  BATGLINT (GL Interface)        BATDLAKE (Data Lake)
  =======================        =====================
  +------------------+           +------------------+
  | Unposted deals   |           | Today's AUDIT_LOG|
  | (GL_POSTED='N')  |           | changes          |
  +------------------+           +------------------+
           |                              |
           v                              v
  +------------------+           +------------------+
  | GLFILE DD        |           | OUTFILE DD       |
  | GL posting recs  |           | JSON-like extract|
  | (Rev, COGS,      |           | (full current    |
  |  F&I, Tax)       |           |  records)        |
  +------------------+           +------------------+
```

### Weekly Processing (BATWKL00)

```
  +=====================================================================+
  |                    WEEKLY SUNDAY BATCH                               |
  +=====================================================================+

  +------------------+     +------------------+     +------------------+
  | 1. Age Inventory |     | 2. Warranty      |     | 3. Recall        |
  | Update           |     | Expiration       |     | Completion %     |
  | DAYS_IN_STOCK    |     | Notices          |     | Update           |
  | on all vehicles  |     | (expiring in     |     | Campaign stats   |
  +------------------+     | 30 days)         |     | recalculated     |
                           +------------------+     +------------------+

  BATVAL00 (Data Validation - also weekly)
  =========================================
  +------------------+
  | Orphan check:    |
  | - Deals w/o      |
  |   customers      |
  | - Vehicles w/o   |
  |   dealers        |
  | VIN checksum     |
  | Duplicate detect |
  +------------------+
           |
           v
  +------------------+
  | SYSPRINT DD      |
  | Exception report |
  +------------------+
```

### Monthly Processing (BATMTH00)

```
  +=====================================================================+
  |                 MONTHLY CLOSE (LAST BUSINESS DAY)                   |
  +=====================================================================+

  +------------------+     +------------------+     +------------------+
  | 1. Month-End     |     | 2. Counter       |     | 3. Archive Old   |
  | Statistics       |     | Rollover         |     | Deals            |
  |                  |     |                  |     |                  |
  | Per dealer:      |     | Reset SOLD_MTD   |     | Completed deals  |
  | - Total deals    |     | on STOCK_POSITION|     | > 18 months      |
  | - Total revenue  |     | table            |     | -> ARCHIVE table |
  | - Gross profit   |     |                  |     |                  |
  | - F&I income     |     |                  |     |                  |
  +------------------+     +------------------+     +------------------+
           |
           v
  +------------------+
  | MONTHLY_SNAPSHOT |
  | table            |
  +------------------+
```

### Quarterly Processing (BATPUR00)

```
  +=====================================================================+
  |                    QUARTERLY PURGE/ARCHIVE                          |
  +=====================================================================+

  +------------------+     +------------------+     +------------------+
  | 1. Archive       |     | 2. Purge         |     | 3. Purge         |
  | Registrations    |     | Audit Log        |     | Recall Notifs    |
  | > 2 years old    |     | > 3 years old    |     | > 1 year old     |
  | Status -> ARCH   |     | DELETE rows      |     | DELETE expired   |
  +------------------+     +------------------+     +------------------+
```

## 6. External Integration Flows

### Outbound Integrations

```
  +===========+                                    +=============+
  | AUTOSALES |                                    | EXTERNAL    |
  | DB2       |                                    | SYSTEMS     |
  +===========+                                    +=============+

  CUSTOMER -----> [BATCRM00] ---pipe-delimited---> CRM SYSTEM
  (changed since                                   (Customer profiles,
   last sync)                                       purchase history)

  VEHICLE ------> [BATDMS00] ---header/detail----> DMS SYSTEM
  SALES_DEAL --->                                  (Inventory + deals)

  SALES_DEAL ---> [BATGLINT] ---fixed-format-----> GENERAL LEDGER
  (unposted)                                       (Revenue, COGS,
                                                    F&I, Tax entries)

  AUDIT_LOG ----> [BATDLAKE] ---JSON-like--------> DATA LAKE
  (today's                                         (Full changed records
   changes)                                         for analytics)
```

### Inbound Integrations

```
  +=============+                                  +===========+
  | EXTERNAL    |                                  | AUTOSALES |
  | SYSTEMS     |                                  | DB2       |
  +=============+                                  +===========+

  MANUFACTURER --> [BATINB00] ---fixed-length-----> VEHICLE
  (Allocation      Validate,                        MODEL_MASTER
   feed)           Transform,
                   Reject bad recs

  MANUFACTURER --> [WRCRCLB0] ---campaign+VINs---> RECALL_CAMPAIGN
  (Recall feed)    Validate VINs,                   RECALL_VEHICLE
                   Insert records

  CARRIER -------> [PLITRNS0  ---EDI 214---------> TRANSIT_STATUS
  (Shipment         via                             SHIPMENT
   status)          COMEDIL0]

  CARRIER -------> [COMEDIL0] ---EDI 856---------> SHIPMENT_VEHICLE
  (Ship notice)     Parse ASN,                      VEHICLE
                    Match VINs
```

### Checkpoint/Restart Pattern (All Batch Programs)

```
  +------------------+
  | Start Batch Job  |
  +------------------+
           |
           v
  +------------------+     +------------------+
  | Check for        |---->| Pending Restart? |
  | Restart          |     | (COMCKPL0 INIT)  |
  | (COMCKPL0 XRST)  |     +------------------+
  +------------------+            |
           |                 YES  |  NO
           v                      v
  +------------------+     +------------------+
  | Resume from      |     | Start from       |
  | last checkpoint  |     | beginning        |
  +------------------+     +------------------+
           |                      |
           +----------+-----------+
                      |
                      v
  +------------------+
  | Process Records  |
  | (cursor loop)    |<-----------+
  +------------------+            |
           |                      |
           v                      |
  +------------------+            |
  | Every N records: |            |
  | COMCKPL0 CHKP    |            |
  | (N = 200-1000)   |            |
  +------------------+            |
           |                      |
           +------[more]----------+
           |
           v [done]
  +------------------+
  | COMCKPL0 DONE    |
  | Mark Complete    |
  +------------------+
```
