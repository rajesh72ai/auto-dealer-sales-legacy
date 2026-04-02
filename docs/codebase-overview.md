# AUTOSALES Codebase Overview

## System Identity

| Attribute | Value |
|-----------|-------|
| **System Name** | AUTOSALES |
| **Full Title** | Automotive Dealer Sales & Reporting System |
| **Platform** | IBM z/OS Mainframe |
| **Online TP Monitor** | IMS DC (Information Management System - Data Communications) |
| **Batch Framework** | IMS BMP (Batch Message Processing) |
| **Relational Database** | DB2 for z/OS (Schema: AUTOSALE) |
| **Hierarchical Database** | IMS Hierarchical DB (5 DBDs) |
| **Screen Definitions** | MFS (Message Format Service) |
| **Language** | COBOL (Enterprise COBOL for z/OS) |
| **Job Control** | JCL (Job Control Language) |
| **Scripting** | REXX, CLIST |

## File Inventory

| Category | Directory | Count | Approx. SLOC |
|----------|-----------|------:|-------------:|
| COBOL - Online Programs | `cbl/online/` | 76 | ~48,474 |
| COBOL - Batch Programs | `cbl/batch/` | 11 | ~7,003 |
| COBOL - Common Modules | `cbl/common/` | 16 | ~8,904 |
| COBOL - Report Programs | `cbl/reports/` | 14 | (included in batch) |
| Copybooks - Common | `cpy/common/` | 14 | ~1,512 |
| Copybooks - DCLGEN | `cpy/dclgen/` | 44 | ~2,400 |
| MFS Screen Definitions | `mfs/` | 32 | ~8,274 |
| JCL - Batch/Reports/Setup/Utility | `jcl/` | 40 | ~4,443 |
| PSB (Program Specification Block) | `psb/` | 16 | ~527 |
| DBD (Database Description) | `dbd/` | 5 | ~371 |
| REXX Procedures | `rexx/` | 8 | ~1,682 |
| CLIST Procedures | `clist/` | 5 | ~919 |
| DDL (SQL Schema) | `ddl/` | 1 | ~500 |
| Sample Data (SQL) | `data/` | 10 | ~500 |
| **Total** | | **~292 files** | **~84,509** |

### Online Programs by Module (76 total)

| Module | Programs | Description |
|--------|---------|-------------|
| ADM | 8 | Administration (Security, Config, Dealer, Model, Pricing, Tax, Incentive, F&I Products) |
| CUS | 7 | Customer Management (Add, Update, Inquiry, List, History, Credit, Lead) |
| SAL | 8 | Sales Process (Quote, Negotiate, Approve, Complete, Cancel, Incentive, Trade-in, Validate) |
| FIN | 7 | Finance & Insurance (Application, Approval, Calculator, Lease Calc, Credit Check, Documents, F&I Products) |
| FPL | 5 | Floor Plan (Add, Inquiry, Interest, Payoff, Report) |
| PLI | 8 | Production & Logistics (Production, Allocation, Shipment, Transit, Delivery, ETA, PDI, Reconciliation) |
| REG | 5 | Registration & Title (Generate, Validate, Submit, Status, Inquiry) |
| STK | 10 | Stock Management (Inquiry, Summary, Aging, Alerts, Adjust, Hold, Reconcile, Snapshot, Transfer, Valuation) |
| VEH | 8 | Vehicle Management (Inquiry, List, Receive, Update, Allocate, Transfer, Aging, Location) |
| WRC | 6 | Warranty & Recall (Warranty Inquiry, Registration, Recall Mgmt, Recall Batch, Notification, Claims Report) |

## Architecture Description

### Dual Data Store Architecture

AUTOSALES employs a dual data store architecture:

1. **DB2 Relational Database** -- Primary data store with 53 tables under schema `AUTOSALE`. Used for all transactional data including deals, customers, vehicles, finance, and inventory. Accessed via embedded SQL (EXEC SQL) in COBOL programs.

2. **IMS Hierarchical Database** -- Five database descriptions (DBDAUTO1 through DBDAUTO5) provide hierarchical views of:
   - DBDAUTO1: Vehicle master with options, status history, and lot location as child segments
   - DBDAUTO2: Customer master with deal history and credit check segments
   - DBDAUTO3: Deal master with line items, trade-in, and finance segments
   - DBDAUTO4: Floor plan master with interest accrual and payment segments
   - DBDAUTO5: Warranty/recall with campaign and notification segments

### Online Transaction Processing

All 76 online programs execute as IMS DC MPP (Message Processing Programs):
- Entry point: `ENTRY 'DLITCBL' USING IO-PCB DB-PCB-1`
- Input: IMS GU (Get Unique) call to receive terminal message
- Output: IMS ISRT (Insert) call to send response message
- Screens: MFS (Message Format Service) definitions for 3270 terminal display
- Each transaction has a 4-character IMS transaction code (e.g., ADMS, SALQ, FNAP)

### Batch Processing

11 batch programs run as IMS BMP (Batch Message Processing) programs:
- Daily: BATDLY00 -- Status updates, deal expiration, floor plan interest
- Weekly: BATWKL00 -- Inventory aging, warranty notices, recall updates
- Monthly: BATMTH00 -- Month-end statistics, counter rollover, deal archival
- Quarterly: BATPUR00 -- Purge/archive of aged data
- Integration: BATCRM00 (CRM), BATDMS00 (DMS), BATGLINT (GL), BATDLAKE (Data Lake), BATINB00 (Manufacturer Inbound)
- Utility: BATVAL00 (Data Validation), BATRSTRT (Restart Utility)

All batch programs use checkpoint/restart via COMCKPL0 at configurable intervals (typically every 200-1000 records).

## Module Organization

### Functional Modules (Prefix Convention)

| Prefix | Module | Scope |
|--------|--------|-------|
| ADM | Administration | System config, security, dealer/model/pricing master data |
| CUS | Customer | Customer CRUD, search, credit pre-qualification, lead tracking |
| SAL | Sales Process | Deal lifecycle: quote, negotiate, approve, complete, cancel |
| FIN | Finance & Insurance | Finance applications, loan/lease calc, credit check, F&I products, documents |
| FPL | Floor Plan | Floor plan add, inquiry, daily interest accrual, payoff |
| PLI | Production & Logistics | Production receipt, allocation, shipment, transit, delivery, PDI |
| REG | Registration & Title | Registration generation, validation, submission, DMV status tracking |
| STK | Stock Management | Inventory counts, aging, alerts, reconciliation, transfers, valuation |
| VEH | Vehicle | Vehicle master CRUD, receiving, status updates, lot location |
| WRC | Warranty & Recall | Warranty registration/inquiry, recall campaigns, notifications |
| BAT | Batch | All batch processing programs |
| COM | Common | Shared callable modules (16 programs) |
| RPT | Reports | 14 report generation programs |

### Common Modules (16 Shared Callable Programs)

| Module | Purpose | Called By |
|--------|---------|----------|
| COMLGEL0 | Audit logging (INSERT into AUDIT_LOG) | Nearly all programs |
| COMDBEL0 | DB2 error handling and SQLCODE evaluation | Nearly all programs |
| COMFMTL0 | Field formatting (currency, phone, SSN, VIN, percentage) | Most display programs |
| COMMSGL0 | IMS DC message builder (LL/ZZ prefix, severity) | Many online programs |
| COMTAXL0 | Tax calculation (state/county/city rates, fees) | SAL, FIN, REG modules |
| COMPRCL0 | Vehicle pricing engine (MSRP, invoice, holdback, gross) | SAL, STK, VEH modules |
| COMLONL0 | Loan amortization calculation | FIN module |
| COMLESL0 | Lease payment calculation | FIN module |
| COMINTL0 | Floor plan interest calculation (daily accrual) | FPL, BAT modules |
| COMVALD0 | VIN validation (17-char, check digit, NHTSA) | SAL, VEH, FPL, PLI, REG |
| COMVINL0 | VIN decoder (WMI, VDS, year, plant, sequence) | VEH, PLI modules |
| COMSEQL0 | Sequence number generator (deals, registrations, etc.) | SAL, FIN, PLI, STK |
| COMCKPL0 | Checkpoint/restart handler (IMS CHKP/XRST) | All batch programs |
| COMSTCK0 | Stock count update (RECV, SOLD, HOLD, RLSE, TRNI, TRNO) | STK, VEH, SAL, PLI |
| COMDTEL0 | Date/time utilities (Julian, Gregorian, days between, aging) | Multiple modules |
| COMEDIL0 | EDI message parser (EDI 214, EDI 856) | PLI module |

## External Integrations

| Integration | Direction | Format | Programs | Schedule |
|-------------|-----------|--------|----------|----------|
| CRM System | Outbound | Pipe-delimited flat file | BATCRM00 | Daily |
| DMS (Dealer Mgmt System) | Outbound | Fixed-length header/detail | BATDMS00 | Daily |
| General Ledger | Outbound | Fixed-format GL posting records | BATGLINT | Daily |
| Data Lake | Outbound | JSON-like delimited extract | BATDLAKE | Daily |
| Manufacturer (Allocation) | Inbound | Fixed-length allocation records | BATINB00 | As received |
| Manufacturer (Recall) | Inbound | Recall campaign + VIN list | WRCRCLB0 | As received |
| EDI 214 (Carrier Status) | Inbound | ANSI X12 004010 ('*' element, '~' segment) | PLITRNS0 via COMEDIL0 | As received |
| EDI 856 (Ship Notice) | Inbound | ANSI X12 004010 | COMEDIL0 | As received |
| Credit Bureau | Outbound/Inbound | Simulated in CUSCRED0/FINCHK00 | CUSCRED0, FINCHK00 | Online |
| State DMV | Outbound | Registration submissions | REGSUB00 | Online |

## Security Model

Security is handled by **ADMSEC00** (IMS Transaction: ADMS):

1. **Authentication**: User ID + password validated against `SYSTEM_USER` DB2 table
2. **Password Storage**: Password hash comparison (simplified for demo; production would use external crypto module)
3. **Account Lockout**: After 5 consecutive failed login attempts, `LOCKED_FLAG` set to 'Y'; requires administrator to unlock
4. **Active Flag**: Inactive accounts (`ACTIVE_FLAG != 'Y'`) are rejected at login
5. **User Types**: A=Admin, G=General Manager, M=Manager, S=Salesperson, F=F&I Manager, C=Clerk
6. **Role-Based Access**: Approval authority controlled by user type:
   - Standard deals: Manager (M), GM (G), or Admin (A) can approve
   - Loser deals (negative front gross): Only GM (G) or Admin (A)
   - Invoice visibility: Manager and above only (SALNEG00)
7. **Audit Trail**: All login attempts (success and failure) logged via COMLGEL0 to AUDIT_LOG table
8. **Session**: On success, `LAST_LOGIN_TS` updated, `FAILED_ATTEMPTS` reset to 0; main menu (ASMNU00) returned

## DB2 Database Schema

The relational database contains 53 tables organized into functional groups:

- **Admin/Reference**: SYSTEM_USER, SYSTEM_CONFIG, DEALER, MODEL_MASTER, PRICE_MASTER, INCENTIVE_PROGRAM, TAX_RATE
- **Customer**: CUSTOMER, CUSTOMER_LEAD, CREDIT_CHECK
- **Vehicle**: VEHICLE, VEHICLE_OPTION, VEHICLE_STATUS_HIST, LOT_LOCATION
- **Sales**: SALES_DEAL, DEAL_LINE_ITEM, SALES_APPROVAL, TRADE_IN, INCENTIVE_APPLIED
- **Finance**: FINANCE_APP, LEASE_TERMS, FINANCE_PRODUCT
- **Floor Plan**: FLOOR_PLAN_VEHICLE, FLOOR_PLAN_INTEREST, FLOOR_PLAN_LENDER
- **Production/Logistics**: PRODUCTION_ORDER, SHIPMENT, SHIPMENT_VEHICLE, TRANSIT_STATUS, PDI_SCHEDULE
- **Registration**: REGISTRATION, TITLE_STATUS
- **Warranty/Recall**: WARRANTY, WARRANTY_CLAIM, RECALL_CAMPAIGN, RECALL_VEHICLE, RECALL_NOTIFICATION
- **Stock**: STOCK_POSITION, STOCK_ADJUSTMENT, STOCK_TRANSFER, STOCK_SNAPSHOT, MONTHLY_SNAPSHOT
- **Batch/Control**: AUDIT_LOG, BATCH_CONTROL, BATCH_CHECKPOINT, RESTART_CONTROL, DAILY_SUMMARY, MONTHLY_SUMMARY
