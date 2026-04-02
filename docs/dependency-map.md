# AUTOSALES Dependency Map

> Generated from static analysis of 113 COBOL source files (74,293 SLOC) and 59 copybooks.
> Date: 2026-03-29

---

## 1. Program-to-Copybook Matrix

### 1.1 Common Working Storage Copybooks

| Copybook | Purpose | Used By (Count) | Programs |
|----------|---------|-----------------|----------|
| WSSQLCA | DB2 SQLCA communication area | 60+ | Nearly all online/batch/common programs |
| WSIOPCB | IMS I/O PCB mask | 55+ | All online programs (IMS DC interface) |
| WSMSGFMT | Message formatting areas | 35+ | Most online transaction programs |
| WSCKPT00 | Checkpoint/restart areas | 11 | All batch programs (BATDLY00, BATWKL00, BATDLAKE, BATVAL00, BATCRM00, BATPUR00, BATGLINT, BATMTH00, BATDMS00, BATINB00, BATRSTRT) |
| WSRSTCTL | Restart control fields | 8 | BATDLY00, BATWKL00, BATVAL00, BATPUR00, BATMTH00, BATGLINT, BATDLY00, COMCKPL0 (via DCLRSTCT) |
| WSAUDIT | Audit trail working storage | 3 | CUSLEAD0, CUSCRED0, CUSADD00 |
| WSCOMMON | Common working storage | Shared | Infrastructure copybook |
| WSEDI000 | EDI layout structures | 1 | COMEDIL0 |
| WSFPL000 | Floor plan working storage | 1 | COMINTL0 |
| WSPLI000 | Pipeline working storage | Shared | Pipeline modules |
| WSSTOCK0 | Stock working storage | Shared | Stock modules |
| WSWRC000 | Warranty/recall working storage | Shared | Warranty modules |
| WSPARAM | Parameter passing areas | Shared | Cross-module calls |
| WSDBPCB | DB PCB mask | Shared | DL/I access programs |

### 1.2 DCLGEN Copybooks (DB2 Table Layouts)

| Copybook | DB2 Table | Used By Programs |
|----------|-----------|------------------|
| DCLCUSTM | CUSTOMER | CUSADD00, CUSINQ00, CUSLST00, CUSLEAD0, CUSCRED0, CUSHIS00, SALQOT00, SALNEG00, FINCHK00 |
| DCLSLDEL | SALES_DEAL | SALQOT00, SALNEG00, SALINC00, SALCAN00, SALCMP00, SALAPV00, SALVAL00, SALTRD00, CUSHIS00, FINAPP00, FINCHK00 |
| DCLVEHCL | VEHICLE | VEHUPD00, VEHINQ00, VEHTRN00, VEHALL00, VEHRCV00, VEHLOC00, SALQOT00, CUSHIS00, SALINC00, STKHLD00, STKADJT0, COMPRCL0, COMSTCK0 |
| DCLTRDEIN | TRADE_IN | SALQOT00, SALTRD00, CUSHIS00 |
| DCLFINAP | FINANCE_APP | FINAPP00, FINAPV00 |
| DCLFINPR | FINANCE_PRODUCT | FINPRD00 |
| DCLFPVEH | FLOOR_PLAN_VEHICLE | COMINTL0 |
| DCLFPINT | FLOOR_PLAN_INTEREST | COMINTL0 |
| DCLFPLND | FLOOR_PLAN_LENDER | FPL modules |
| DCLTAXRT | TAX_RATE | ADMTAX00, COMTAXL0 |
| DCLPRICE | PRICE_MASTER | ADMPRC00, SALTRD00, SALQOT00, COMPRCL0 |
| DCLMODEL | MODEL_MASTER | ADMMFG00, VEHINQ00, STKINQ00, STKRCN00 |
| DCLSYUSR | SYSTEM_USER | ADMSEC00, CUSADD00, SALQOT00, SALNEG00, SALAPV00 |
| DCLSYSCF | SYSTEM_CONFIG | ADMPRD00, SALVAL00, COMSEQL0 |
| DCLDEALR | DEALER | ADMDLR00 |
| DCLAUDIT | AUDIT_LOG | COMLGEL0 |
| DCLRSTCT | RESTART_CONTROL | COMCKPL0 |
| DCLREGST | REGISTRATION | REG modules |
| DCLWARTY | WARRANTY | WRC modules |
| DCLSTKPS | STOCK_POSITION | STKINQ00, STKRCN00, COMSTCK0 |
| DCLSTKAJ | STOCK_ADJUSTMENT | STKADJT0, STKRCN00 |
| DCLSTKTF | STOCK_TRANSFER | VEHTRN00, STKTRN00 |
| DCLSTKSS | STOCK_SNAPSHOT | STKSNAP0 |
| DCLVHSTH | VEHICLE_STATUS_HIST | VEHUPD00, VEHTRN00, VEHALL00, VEHRCV00, VEHINQ00, COMSTCK0 |
| DCLVHOPT | VEHICLE_OPTION | VEHINQ00, SALQOT00 |
| DCLPRORD | PRODUCTION_ORDER | VEHALL00, PLI modules |
| DCLSHIPM | SHIPMENT | PLISHPN0 |
| DCLSHPVH | SHIPMENT_VEHICLE | PLISHPN0 |
| DCLPDISH | PDI_SCHEDULE | VEHRCV00 |
| DCLLOTLC | LOT_LOCATION | VEHLOC00 |
| DCLDLITM | DEAL_LINE_ITEM | SALQOT00 |
| DCLINCPG | INCENTIVE_PROGRAM | SALINC00 |
| DCLINAPP | INCENTIVE_APPLICATION | SALINC00, SALCAN00 |
| DCLSLAPV | SALES_APPROVAL | SALAPV00 |
| DCLCRDCK | CREDIT_CHECK | CUSCRED0, FINCHK00, SALVAL00 |
| DCLTRNST | TRANSIT_STATUS | PLITRNS0 |
| DCLCSLEAD | CUSTOMER_LEAD | CUSLEAD0 |
| DCLCOMMS | COMMUNICATIONS | Batch CRM |
| DCLDLYSS | DAILY_SALES_SUMMARY | BATDLY00, RPTDLY00 |
| DCLMTHSS | MONTHLY_SALES_SUMMARY | BATMTH00, RPTMTH00 |
| DCLRCCMP | RECALL_CAMPAIGN | WRC modules |
| DCLRCNTF | RECALL_NOTIFICATION | WRCNOTF0 |
| DCLRCVEH | RECALL_VEHICLE | WRCRCLB0, WRCRCL00 |
| DCLTTLST | TITLE_STATUS | REG modules |
| DCLLSTRM | LEASE_TERM | FINLSE00 |

---

## 2. Call Tree (Common Module Dependencies)

### 2.1 Common Modules Called by Program

| Common Module | Purpose | Called By (Count) | Callers |
|---------------|---------|-------------------|---------|
| **COMDBEL0** | DB2 error handler + IMS ROLL | **40+** | Nearly all programs that do DB2 operations |
| **COMLGEL0** | Audit logging (AUDIT_LOG insert) | **35+** | All programs that write audit records |
| **COMCKPL0** | Checkpoint/restart for batch | **11** | All batch programs |
| **COMFMTL0** | Data formatting (currency, phone, etc.) | **20+** | CUSADD00, CUSINQ00, CUSLST00, SALQOT00, VEHINQ00, VEHAGE00, VEHLST00, FPLADD00, FPLRPT00, FPLPAY00, FPLINT00, WRCINQ00, WRCRPT00, STKSNAP0, STKVALS0, STKSUM00, STKAGIN0, ADMDLR00 |
| **COMSTCK0** | Stock position update | **10** | VEHALL00, VEHRCV00, VEHTRN00, VEHUPD00, PLIDLVR0, PLISHPN0, PLIALLO0, SALCMP00, SALCAN00, STKTRN00, STKHLD00, STKADJT0 |
| **COMVINL0** | VIN decode/lookup | **5** | VEHINQ00, VEHRCV00, PLIPROD0, SALTRD00, BATVAL00 |
| **COMVALD0** | VIN validation (check digit) | **7** | VEHALL00, VEHRCV00, PLIDLVR0, PLIPROD0, SALTRD00, WRCRCLB0, REGGEN00, REGVAL00, FPLADD00 |
| **COMTAXL0** | Multi-jurisdiction tax calc | **4** | SALQOT00, SALNEG00, ADMTAX00, REGGEN00 (also called by COMPRCL0) |
| **COMPRCL0** | Vehicle pricing lookup | **4** | SALQOT00, SALNEG00, VEHAGE00 (COMPRCL0 internally calls COMTAXL0) |
| **COMSEQL0** | Sequence number generator | **5** | SALQOT00, FINAPP00, VEHRCV00, VEHTRN00, PLISHPN0, STKTRN00 |
| **COMDTEL0** | Date calculation utility | **6** | CUSHIS00, CUSLEAD0, PLIETA00, PLIRECON, WRCNOTF0, WRCWAR00, STKAGIN0, VEHAGE00 |
| **COMMSGL0** | Message builder/formatter | **5** | ADMSEC00, SALAPV00, STKINQ00, STKALRT0, VEHLST00, PLIRECON |
| **COMEDIL0** | EDI parser (214, 856, 997) | **1** | PLITRNS0 (receives EDI inbound from BATINB00) |
| **COMLONL0** | Loan amortization calculator | **4** | FINCAL00, FINAPV00, FINAPP00, FINDOC00 |
| **COMLESL0** | Lease residual calculator | **1** | FINLSE00 |
| **COMINTL0** | Floor plan interest calculator | **2** | FPLPAY00, FPLINT00 |

### 2.2 Most-Called Modules (Ranked by Call Count)

```
COMDBEL0  ████████████████████████████████████████  40+ programs
COMLGEL0  ███████████████████████████████████████   35+ programs
COMFMTL0  ████████████████████                      20+ programs
COMCKPL0  ███████████                               11  programs
COMSTCK0  ██████████                                10  programs
COMVALD0  ████████                                   8  programs
COMDTEL0  ███████                                    7  programs
COMVINL0  █████                                      5  programs
COMSEQL0  █████                                      5  programs
COMMSGL0  █████                                      5  programs
COMPRCL0  ████                                       4  programs
COMLONL0  ████                                       4  programs
COMTAXL0  ████                                       4  programs
COMINTL0  ██                                         2  programs
COMEDIL0  █                                          1  program
COMLESL0  █                                          1  program
```

### 2.3 IMS DL/I Calls (CBLTDLI)

All online programs use CBLTDLI for:
- **GU (Get Unique):** Reading input messages from IMS DC (IO PCB)
- **ISRT (Insert):** Sending output messages back to the terminal
- **CHKP / XRST:** Checkpoint and restart in batch programs (via COMCKPL0)

---

## 3. Data Store Dependencies (DB2 Tables by Module)

### 3.1 Module-to-Table Access Matrix

| Module | Tables Accessed | Access Type |
|--------|----------------|-------------|
| **SAL (Sales)** | SALES_DEAL, DEAL_LINE_ITEM, CUSTOMER, VEHICLE, VEHICLE_OPTION, PRICE_MASTER, TRADE_IN, INCENTIVE_PROGRAM, INCENTIVE_APPLICATION, SALES_APPROVAL, CREDIT_CHECK, SYSTEM_USER, SYSTEM_CONFIG, AUDIT_LOG | R/W |
| **CUS (Customer)** | CUSTOMER, CUSTOMER_LEAD, CREDIT_CHECK, SALES_DEAL, VEHICLE, TRADE_IN, SYSTEM_USER, AUDIT_LOG | R/W |
| **VEH (Vehicle)** | VEHICLE, VEHICLE_STATUS_HIST, VEHICLE_OPTION, LOT_LOCATION, STOCK_POSITION, STOCK_TRANSFER, PRODUCTION_ORDER, PDI_SCHEDULE, MODEL_MASTER, AUDIT_LOG | R/W |
| **FIN (Finance)** | FINANCE_APP, FINANCE_PRODUCT, SALES_DEAL, CUSTOMER, CREDIT_CHECK, LEASE_TERM, AUDIT_LOG | R/W |
| **FPL (Floor Plan)** | FLOOR_PLAN_VEHICLE, FLOOR_PLAN_INTEREST, FLOOR_PLAN_LENDER, VEHICLE, AUDIT_LOG | R/W |
| **STK (Stock)** | STOCK_POSITION, STOCK_ADJUSTMENT, STOCK_TRANSFER, STOCK_SNAPSHOT, VEHICLE, MODEL_MASTER, AUDIT_LOG | R/W |
| **REG (Registration)** | REGISTRATION, TITLE_STATUS, VEHICLE, SALES_DEAL, TAX_RATE, AUDIT_LOG | R/W |
| **WRC (Warranty/Recall)** | WARRANTY, RECALL_CAMPAIGN, RECALL_VEHICLE, RECALL_NOTIFICATION, VEHICLE, CUSTOMER, AUDIT_LOG | R/W |
| **PLI (Pipeline)** | PRODUCTION_ORDER, SHIPMENT, SHIPMENT_VEHICLE, TRANSIT_STATUS, VEHICLE, VEHICLE_STATUS_HIST, STOCK_POSITION, AUDIT_LOG | R/W |
| **ADM (Admin)** | SYSTEM_USER, SYSTEM_CONFIG, DEALER, MODEL_MASTER, PRICE_MASTER, TAX_RATE, INCENTIVE_PROGRAM, AUDIT_LOG | R/W |
| **BAT (Batch)** | SALES_DEAL, VEHICLE, CUSTOMER, DEALER, FINANCE_APP, REGISTRATION, AUDIT_LOG, DAILY_SALES_SUMMARY, MONTHLY_SALES_SUMMARY, RESTART_CONTROL, RECALL_CAMPAIGN, RECALL_VEHICLE, COMMUNICATIONS | R/W |
| **RPT (Reports)** | SALES_DEAL, VEHICLE, CUSTOMER, DEALER, MODEL_MASTER, FINANCE_APP, WARRANTY, RECALL_CAMPAIGN, STOCK_POSITION, DAILY_SALES_SUMMARY, MONTHLY_SALES_SUMMARY | R |

### 3.2 Shared Tables (Cross-Module Data Dependencies)

Tables accessed by 3+ modules represent critical shared data:

| Table | Accessed By Modules | Significance |
|-------|--------------------|--------------|
| **VEHICLE** | SAL, CUS, VEH, FPL, STK, PLI, WRC, REG, BAT, RPT | **Central entity** - most shared table in the system |
| **SALES_DEAL** | SAL, CUS, FIN, REG, BAT, RPT | Core business transaction |
| **CUSTOMER** | SAL, CUS, FIN, WRC, BAT, RPT | Master customer record |
| **AUDIT_LOG** | ALL modules via COMLGEL0 | Universal audit trail |
| **STOCK_POSITION** | VEH, STK, PLI, BAT | Inventory counts |
| **MODEL_MASTER** | VEH, STK, ADM, BAT, RPT | Reference data |
| **PRICE_MASTER** | SAL, ADM, RPT | Pricing reference |
| **TAX_RATE** | SAL, ADM, REG | Tax calculation |
| **SYSTEM_USER** | SAL, CUS, ADM | Authentication/authorization |
| **SYSTEM_CONFIG** | SAL, ADM | System parameters |

---

## 4. Cross-Module Dependencies

### 4.1 Module Dependency Graph

```
                    +-----------+
                    |   ADM     |  (Admin - Reference Data)
                    | 8 pgms   |
                    | 6,972 LOC|
                    +-----+-----+
                          |
          Reference Data  | (DEALER, MODEL, PRICE, TAX, USER, CONFIG)
                          |
    +----------+----+-----+-----+----+----------+
    |          |         |           |           |
+---v---+ +---v---+ +---v---+ +----v----+ +---v---+
|  CUS  | |  VEH  | |  SAL  | |   FIN   | |  REG  |
|7 pgms | |8 pgms | |8 pgms | | 7 pgms  | |5 pgms |
|5,326  | |5,653  | |6,295  | | 5,135   | |2,873  |
+---+---+ +---+---+ +---+---+ +----+----+ +---+---+
    |         |          |           |          |
    +----+----+    +-----+-----+    +----+-----+
         |         |           |         |
    +----v----+  +-v--------+  +---v-----+
    |   STK   |  |   FPL    |  |   WRC   |
    |10 pgms  |  | 5 pgms   |  | 6 pgms  |
    | 4,886   |  | 2,531    |  | 3,294   |
    +---------+  +----------+  +---------+
         |           |              |
    +----v-----------v--------------v----+
    |              PLI                    |
    |  Pipeline/Logistics (8 pgms)       |
    |  5,709 SLOC                        |
    +----+-------------------------------+
         |
    +----v-----------+
    |     BAT/RPT    |
    | Batch: 11 pgms |  Reports: 14 pgms
    | 7,003 SLOC     |  9,312 SLOC
    +----------------+

```

### 4.2 Dependency Direction Matrix

| Source Module | Depends On | Nature of Dependency |
|--------------|------------|---------------------|
| **SAL** (Sales) | CUS (customer lookup), VEH (vehicle data), FIN (finance check), ADM (pricing/tax/users), STK (stock update) | Heavy cross-module: 5 dependencies |
| **CUS** (Customer) | ADM (user auth) | Light: 1 dependency |
| **VEH** (Vehicle) | STK (stock position), ADM (model reference) | Medium: 2 dependencies |
| **FIN** (Finance) | SAL (deal data), CUS (credit check), ADM (config) | Heavy: 3 dependencies |
| **FPL** (Floor Plan) | VEH (vehicle data), ADM (lender config) | Medium: 2 dependencies |
| **STK** (Stock) | VEH (vehicle data), ADM (model reference) | Medium: 2 dependencies |
| **REG** (Registration) | SAL (deal data), VEH (vehicle data), ADM (tax rates) | Medium: 3 dependencies |
| **WRC** (Warranty) | VEH (vehicle data), CUS (customer data) | Medium: 2 dependencies |
| **PLI** (Pipeline) | VEH (vehicle create), STK (stock update), ADM (reference) | Heavy: 3 dependencies |
| **ADM** (Admin) | None (foundation module) | Independent |
| **BAT** (Batch) | ALL modules (reads from all tables) | Read-heavy: universal |
| **RPT** (Reports) | ALL modules (reads from all tables) | Read-only: universal |

### 4.3 Critical Integration Points

1. **COMSTCK0 (Stock Update)** - Called by VEH, PLI, SAL, STK modules. Single point of stock position mutation. Any error here affects inventory accuracy across the system.

2. **COMPRCL0 -> COMTAXL0 chain** - Pricing calls tax calculation internally. Used by SAL and VEH aging. Financial accuracy depends on this chain.

3. **COMSEQL0 (Sequence Generator)** - Generates deal numbers, shipment IDs, transfer IDs. Single point of ID generation.

4. **COMEDIL0 (EDI)** - External interface point. Only used by PLITRNS0 but critical for manufacturer communication (EDI 214, 856, 997 transactions).

5. **Batch -> Online data flow** - Batch programs (BATDLY00, BATMTH00) aggregate online transaction data into summary tables. Reports read from both online and summary tables.

### 4.4 Module Statistics Summary

| Module | Programs | Total SLOC | Avg SLOC/Pgm | Copybooks Used | COM Calls |
|--------|----------|------------|--------------|----------------|-----------|
| ADM | 8 | 6,972 | 872 | 12 | 4 (COMDBEL0, COMLGEL0, COMFMTL0, COMTAXL0, COMMSGL0) |
| SAL | 8 | 6,295 | 787 | 18 | 7 (COMDBEL0, COMLGEL0, COMPRCL0, COMTAXL0, COMSEQL0, COMSTCK0, COMMSGL0) |
| CUS | 7 | 5,326 | 761 | 12 | 4 (COMDBEL0, COMLGEL0, COMFMTL0, COMDTEL0) |
| VEH | 8 | 5,653 | 707 | 16 | 7 (COMVALD0, COMVINL0, COMSTCK0, COMSEQL0, COMLGEL0, COMDTEL0, COMPRCL0, COMFMTL0) |
| FIN | 7 | 5,135 | 734 | 10 | 4 (COMDBEL0, COMLGEL0, COMLONL0, COMLESL0, COMSEQL0) |
| FPL | 5 | 2,531 | 506 | 6 | 5 (COMDBEL0, COMLGEL0, COMINTL0, COMFMTL0, COMVALD0) |
| STK | 10 | 4,886 | 489 | 10 | 6 (COMDBEL0, COMLGEL0, COMSTCK0, COMFMTL0, COMSEQL0, COMDTEL0, COMMSGL0) |
| REG | 5 | 2,873 | 575 | 6 | 4 (COMDBEL0, COMLGEL0, COMVALD0, COMTAXL0) |
| WRC | 6 | 3,294 | 549 | 6 | 4 (COMDBEL0, COMLGEL0, COMDTEL0, COMVALD0, COMFMTL0) |
| PLI | 8 | 5,709 | 714 | 10 | 7 (COMDBEL0, COMLGEL0, COMVALD0, COMVINL0, COMSTCK0, COMSEQL0, COMEDIL0, COMDTEL0) |
| COM | 17 | 8,914 | 524 | 14 | Internal / foundational |
| BAT | 11 | 7,003 | 637 | 8 | 3 (COMCKPL0, COMDBEL0, COMLGEL0, COMVINL0) |
| RPT | 14 | 9,312 | 665 | -- | Standalone (no COM calls, direct SQL) |

**Grand Total: 113 programs, 74,293 SLOC**
