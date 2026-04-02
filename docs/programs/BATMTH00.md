# BATMTH00 — Monthly Close Processing

## Overview
- **Program ID:** BATMTH00
- **Type:** Batch
- **Source:** cbl/batch/BATMTH00.cbl
- **Lines of Code:** 641
- **Complexity:** High

## Purpose
Runs on the last business day of each month to perform three monthly close functions: calculates dealer month-end statistics and inserts/updates MONTHLY_SNAPSHOT, rolls monthly counters (resets SOLD_MTD on STOCK_POSITION), and archives completed deals older than 18 months by updating their status.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Three-phase processing.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.DEALER | SELECT | Iterate active dealers |
| AUTOSALE.SALES_DEAL | SELECT/UPDATE | Aggregate monthly stats; archive old deals |
| AUTOSALE.MONTHLY_SNAPSHOT | INSERT/UPDATE | Create/update dealer monthly snapshots |
| AUTOSALE.STOCK_POSITION | UPDATE | Reset SOLD_MTD counters |
| AUTOSALE.FINANCE_PRODUCT | SELECT | Aggregate F&I gross per dealer |
| AUTOSALE.VEHICLE | SELECT | Join for average days-to-sell |
| AUTOSALE.RESTART_CONTROL | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management (INIT/CHKP/DONE) |
| COMLGEL0 | Audit logging for archived deals |

### Key Business Logic
- **Phase 1 - Monthly Snapshots:** For each active dealer, calculates: units sold, total revenue, total gross, F&I gross (from FINANCE_PRODUCT join), average days to sell (from VEHICLE join), and F&I per deal (F&I gross / units). Inserts into MONTHLY_SNAPSHOT; on duplicate (-803), updates instead. Frozen flag set to 'Y'.
- **Phase 2 - Roll Counters:** Mass UPDATE on STOCK_POSITION setting SOLD_MTD = 0 for all rows.
- **Phase 3 - Archive Deals:** Selects completed deals (status DL/CA/UW) with delivery date <= 18 months ago. Updates status to 'UW' (archived). In production, would copy to SALES_DEAL_ARCHIVE then delete.
- **Archive cutoff:** Calculated via DB2: CURRENT DATE - 18 MONTHS.
- **Checkpointing:** Every 100 dealers.

### Copybooks Used
- WSCKPT00
- WSRSTCTL
- SQLCA

### Input/Output
- **Input:** DB2 tables only
- **Output:** DB2 table updates/inserts, DISPLAY statements to SYSOUT

## Modernization Notes
- **Target:** Reporting/Analytics service for snapshots; Scheduled maintenance jobs for archival
- **Key considerations:** The snapshot calculation logic contains important KPI formulas (F&I per deal, avg days to sell). The archive function should use proper archive tables in production. The MTD counter roll is a simple but critical operation.
- **Dependencies:** Depends on COMCKPL0, COMLGEL0. Monthly reporting depends on MONTHLY_SNAPSHOT data.
