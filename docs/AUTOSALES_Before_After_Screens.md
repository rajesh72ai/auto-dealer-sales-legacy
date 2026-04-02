# AUTOSALES — Before & After: IMS DC Screens vs Modern React UI

This document shows representative legacy IMS DC terminal screens alongside their modern React equivalents, demonstrating the transformation from 3270 green-screen terminals to a polished web application.

---

## 1. Vehicle Inquiry (VEHINQ00 → VehicleDetailPage)

### BEFORE: IMS DC Terminal (MFS Screen)
```
 AUTOSALES                  VEHICLE INQUIRY                    03/30/2026
 TRAN: VEHI                                                    USER: TSMITH01
 ============================================================================
 VIN: 1FTFW1E53NFA00101          STOCK#: F01-0101
 ---- VEHICLE INFORMATION ----
 YEAR: 2025  MAKE: FRD  MODEL: F150XL    COLOR: WHT/GRY
 STATUS: AV (AVAILABLE)          DEALER: DLR01
 LOT: FRNT01                     PDI: Y   DAMAGE: N
 RECV DATE: 07/05/2025           DAYS IN STOCK: 088
 ODOMETER: 000012

 ---- INSTALLED OPTIONS ----
 CODE   DESCRIPTION                        PRICE
 XLTPKG XLT CHROME APPEARANCE PKG       1,995.00
 TOWMAX MAX TRAILER TOW PACKAGE         1,295.00
 BEDLNR SPRAY-IN BEDLINER                 595.00
 NAVSYS NAVIGATION SYSTEM W/ SYNC 4       795.00

 ---- STATUS HISTORY ----
 SEQ  OLD  NEW  CHANGED BY  REASON                     DATE
 004  DL   AV   TSMITH01    PDI COMPLETED              07/05/25
 003  IT   DL   SYSTEM      DELIVERED TO DEALER DOCK   07/01/25
 002  AL   IT   SYSTEM      SHIPPED VIA TRUCK JBHT     06/25/25
 001  PR   AL   SYSTEM      ALLOCATED TO DLR01         06/15/25

 PF3=EXIT  PF5=UPDATE  PF7=BACK  PF8=FORWARD
```

### AFTER: React VehicleDetailPage
- Tabbed interface (Info | Options | History | Actions)
- Color-coded status badges (green for AV, amber for HD, etc.)
- VIN auto-decode panel showing Country, Manufacturer, Model Year, Plant
- Options table with formatted prices
- Status history as a visual timeline with icons
- Action buttons: Update Status, Hold/Release, Allocate

---

## 2. Deal Pipeline (SALQOT00/SALNEG00 → DealPipelinePage)

### BEFORE: IMS DC Terminal
```
 AUTOSALES                  DEAL LISTING                       03/30/2026
 TRAN: SALL                                                    USER: JPATTER1
 ============================================================================
 DEALER: DLR01    STATUS FILTER: __

 DEAL#      CUSTOMER         VEHICLE              STATUS   PRICE       DATE
 ---------- ---------------- -------------------- -------- ----------- --------
 D000000001 HENDERSON, M.    2025 FRD F150XL      FI       38,608.94  03/15/26
 D000000002 MITCHELL, S.     2025 FRD MUSTGT      DL       52,340.00  03/10/26
 D000000003 GARCIA, R.       2025 FRD ESCSEL      AP       34,125.00  03/20/26
 D000000004 WOLFE, J.        2026 FRD F150XL      NE       41,200.00  03/25/26
 D000000005 THOMPSON, D.     2025 FRD MUSTGT      WS       48,900.00  03/28/26

 PAGE: 01 OF 01                 TOTAL DEALS: 005

 PF3=EXIT  PF5=NEW DEAL  PF7=PREV PAGE  PF8=NEXT PAGE
```

### AFTER: React DealPipelinePage
- Status tabs: All | Active | Delivered | Cancelled
- Color-coded deal type badges (New, Used, Lease, CPO)
- Status pipeline visualization (WS→NE→PA→AP→FI→DL)
- Dealer and status filter dropdowns
- Click-through to deal detail with full pricing breakdown
- "New Deal" wizard (3-step: Customer → Vehicle → Terms)

---

## 3. Floor Plan Exposure Report (FPLRPT00 → FloorPlanReportPage)

### BEFORE: IMS DC Terminal
```
 AUTOSALES             FLOOR PLAN EXPOSURE REPORT              03/30/2026
 TRAN: FPLR                                                    USER: JPATTER1
 ============================================================================
 DEALER: DLR01 - LAKEWOOD FORD

 ---- GRAND TOTALS ----
 TOTAL VEHICLES:    015    TOTAL BALANCE:    465,000.00
 TOTAL INTEREST:  3,250.00  WTD AVG RATE:       5.25%
 AVG DAYS ON FLOOR:  045

 ---- BY LENDER ----
 LENDER     VEHICLES  BALANCE       INTEREST    AVG RATE  AVG DAYS
 ALLY1      008       248,000.00    1,750.00    4.50%     038
 CHASE      005       155,000.00    1,100.00    6.00%     052
 BMWFS      002        62,000.00      400.00    5.75%     048

 ---- AGE BUCKETS ----
 0-30 DAYS:  005    31-60 DAYS:  006    61-90 DAYS:  003    91+ DAYS:  001

 ---- NEW/USED SPLIT ----
 NEW:  012  ($372,000)     USED:  003  ($93,000)

 PF3=EXIT  PF6=PRINT
```

### AFTER: React FloorPlanReportPage
- 5 KPI summary cards with formatted values
- Donut chart for New vs Used split
- Bar chart for age bucket distribution
- Lender breakdown table with pagination
- Print button for reports
- Dealer selector dropdown

---

## 4. Finance Calculator (FINCAL00 → LoanCalculatorPage)

### BEFORE: IMS DC Terminal
```
 AUTOSALES               LOAN PAYMENT CALCULATOR                03/30/2026
 TRAN: FNCL                                                     USER: TSMITH01
 ============================================================================
 PRINCIPAL:    30,000.00    APR:  5.90%    TERM: 060 MO
 DOWN PAYMENT:  5,000.00    NET:  25,000.00

 ---- PRIMARY CALCULATION ----
 MONTHLY PAYMENT:      482.63
 TOTAL OF PAYMENTS: 28,957.80
 TOTAL INTEREST:     3,957.80

 ---- TERM COMPARISON ----
 TERM    MONTHLY     TOTAL PMT    TOTAL INT
 036     758.93      27,321.48    2,321.48
 048     588.45      28,245.60    3,245.60
 060     482.63      28,957.80    3,957.80
 072     413.22      29,751.84    4,751.84

 ---- AMORTIZATION (FIRST 12 MONTHS) ----
 MO  PAYMENT    PRINCIPAL   INTEREST   CUM INT    BALANCE
 01   482.63     359.63     123.00     123.00    24,640.37
 02   482.63     361.40     121.23     244.23    24,278.97
 03   482.63     363.18     119.45     363.68    23,915.79
 ...

 PF3=EXIT
```

### AFTER: React LoanCalculatorPage
- Interactive sliders for APR and term
- Real-time recalculation as inputs change
- Side-by-side term comparison cards (36/48/60/72/84 months)
- Scrollable amortization schedule table
- Down payment impact visualization
- Clean, dealer-friendly design

---

## 5. Stock Adjustment (STKADJT0 → StockAdjustmentsPage)

### BEFORE: IMS DC Terminal
```
 AUTOSALES              STOCK ADJUSTMENT ENTRY                  03/30/2026
 TRAN: STKA                                                     USER: JPATTER1
 ============================================================================
 DEALER: DLR01    VIN: 1FTFW1E53NFA00102

 ADJUSTMENT TYPE: PH  (DM=DAMAGE WO=WRITEOFF RC=RECLASS PH=PHYSICAL OT=OTHER)
 REASON: ANNUAL PHYSICAL INVENTORY COUNT
 ADJUSTED BY: JPATTER1

 ---- VEHICLE CURRENT STATUS ----
 2025 FRD F150XL  STATUS: AV  STOCK#: F01-0102

 ---- RESULT ----
 ADJUST ID: 000001
 OLD STATUS: AV    NEW STATUS: AV
 TIMESTAMP: 2025-12-31 16:00:00

 MSG: ADJUSTMENT RECORDED SUCCESSFULLY

 PF3=EXIT  PF5=SUBMIT
```

### AFTER: React StockAdjustmentsPage
- Paginated adjustment history table with all columns
- "New Adjustment" modal with type dropdown (Damage, Write-Off, Reclassify, Physical Count, Other)
- Dealer filter
- Status change badges
- CSV export button

---

## 6. Batch Job Dashboard (BATRSTRT → BatchJobsPage)

### BEFORE: IMS DC Terminal
```
 AUTOSALES              BATCH RESTART CONTROL                   03/30/2026
 TRAN: BTRS                                                     USER: SYSADMIN
 ============================================================================
 FUNC: DISP  (DISP=DISPLAY  RESET=RESET  COMPL=COMPLETE)

 PROGRAM    DESCRIPTION              LAST RUN     STATUS  RECORDS  STEP
 ---------- ------------------------ ------------ ------- -------- ----
 BATDLY00   DAILY END OF DAY         03/29/2026   OK      000142   003
 BATMTH00   MONTHLY CLOSE            02/28/2026   OK      000089   005
 BATWKL00   WEEKLY PROCESSING        03/28/2026   OK      000050   002
 BATPUR00   PURGE/ARCHIVE            03/01/2026   OK      001250   003
 BATVAL00   DATA VALIDATION          03/29/2026   WARN    000003   001
 BATGLINT   GL POSTING               03/29/2026   OK      000045   004
 BATCRM00   CRM FEED EXTRACT         03/29/2026   OK      000320   002
 BATDMS00   DMS INTERFACE            03/29/2026   OK      000180   003
 BATDLAKE   DATA LAKE EXTRACT        03/29/2026   OK      000890   005
 BATINB00   INBOUND VEHICLE FEED     03/28/2026   OK      000015   001
 BATRSTRT   RESTART UTILITY          N/A          N/A     N/A      N/A

 PF3=EXIT  PF5=RESET  PF6=COMPLETE
```

### AFTER: React BatchJobsPage
- Card-based job listing with color-coded health badges (OK/WARN/CRIT)
- One-click "Run Now" trigger buttons for each job
- Checkpoint management panel (Display, Reset, Complete)
- Run result display with phase details
- Last run timestamp with relative time ("2 hours ago")

---

## 7. Customer Inquiry (CUSINQ00 → CustomersPage)

### BEFORE: IMS DC Terminal
```
 AUTOSALES                CUSTOMER INQUIRY                     03/30/2026
 TRAN: CUSI                                                    USER: TSMITH01
 ============================================================================
 SEARCH: LN (LN=LAST NAME  FN=FIRST  PH=PHONE  DL=DRV LIC  ID=CUST ID)
 VALUE: HENDERSON                              DEALER: DLR01

 ID     NAME                PHONE         CITY          ST  TYPE  SOURCE
 ------ ------------------- ------------- ------------- --- ----- ------
 001001 HENDERSON, MICHAEL  303-555-9101  LAKEWOOD      CO  I     WLK
 001002 MITCHELL, SARAH     303-555-9201  ARVADA        CO  I     WEB
 001003 GARCIA, ROBERT      303-555-9301  DENVER        CO  B     REF
 001004 WOLFE, JENNIFER     303-555-9402  LAKEWOOD      CO  I     WLK
 001005 THOMPSON, DAVID     303-555-9502  ARVADA        CO  I     RPT
 001006 REYES, AMANDA       303-555-9602  DENVER        CO  I     ADV

 PAGE: 01 OF 01                     TOTAL: 006

 PF3=EXIT  PF5=ADD  PF7=PREV  PF8=NEXT  ENTER=SELECT
```

### AFTER: React CustomersPage
- Dealer selector + search by Last Name/First Name/Phone/DL/ID
- DataTable with sortable columns
- Customer type badges (Individual, Business, Fleet)
- Source code labels (Walk-in, Phone, Website, Referral, etc.)
- Click-through to customer detail with contact info, credit history
- "Add Customer" modal with full form

---

## Summary: Before vs After

| Aspect | IMS DC (Before) | React (After) |
|--------|----------------|---------------|
| Interface | Fixed 80x24 green text | Responsive web, any screen size |
| Navigation | Transaction codes (VEHI, FPLR, CUSI) | Collapsible sidebar with 8 groups |
| Data Entry | Tab between fixed fields | Modern forms with validation |
| Output | Fixed-width text, no color | Color badges, charts, cards |
| Pagination | PF7/PF8 keys, 12 rows | Click/scroll, configurable page size |
| Export | Print screen or SYSOUT | CSV download, one click |
| Help | F1 = canned text | Tooltips, inline validation |
| Access | 3270 terminal emulator | Any web browser |
| Response Time | Sub-second (mainframe) | Sub-second (local Docker) |

---

*These screen representations are based on the actual legacy COBOL program documentation (MFS message formats) and the implemented React pages.*
