# BATWKL00 — Weekly Batch Processing

## Overview
- **Program ID:** BATWKL00
- **Type:** Batch
- **Source:** cbl/batch/BATWKL00.cbl
- **Lines of Code:** 642
- **Complexity:** High

## Purpose
Weekly batch that runs every Sunday to perform three tasks: ages inventory by updating DAYS_IN_STOCK on all vehicles currently in dealer stock, generates warranty expiration notices for warranties expiring within 30 days, and updates recall campaign completion percentages based on current recall vehicle statuses.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Three-phase processing.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT/UPDATE | Read vehicles in stock, update DAYS_IN_STOCK |
| AUTOSALE.WARRANTY | SELECT | Find warranties expiring within 30 days |
| AUTOSALE.SALES_DEAL | SELECT | Join for customer ID on warranty notices |
| AUTOSALE.CUSTOMER | SELECT | (implicit via join) |
| AUTOSALE.RECALL_CAMPAIGN | SELECT/UPDATE | Read active campaigns, update completion counts/status |
| AUTOSALE.RECALL_VEHICLE | SELECT | Count completed vs total affected vehicles per campaign |
| AUTOSALE.RECALL_NOTIFICATION | SELECT/INSERT | Check for existing notices; insert new expiry notices |
| AUTOSALE.RESTART_CONTROL | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management (INIT/CHKP/DONE) |

### Key Business Logic
- **Phase 1 - Inventory Aging:** For each vehicle in status AV/HD/DL with a receive date, calculates DAYS(CURRENT DATE) - DAYS(RECEIVE_DATE) and updates DAYS_IN_STOCK.
- **Phase 2 - Warranty Notices:** Finds active warranties expiring between today and today+30 days (joined with SALES_DEAL for customer). Checks if a notice was already sent in the last 30 days. If not, inserts a RECALL_NOTIFICATION with type 'M' (Mailing) and recall_id 'WAREXP'.
- **Phase 3 - Recall Completion:** For each active recall campaign, counts completed vehicles (status 'CM') and total affected vehicles from RECALL_VEHICLE. Updates RECALL_CAMPAIGN with current counts. If all vehicles are completed, marks campaign status as 'C' (Complete).
- **Checkpointing:** Every 500 records.

### Copybooks Used
- WSCKPT00
- WSRSTCTL
- SQLCA

### Input/Output
- **Input:** DB2 tables only
- **Output:** DB2 updates/inserts, DISPLAY statements to SYSOUT

## Modernization Notes
- **Target:** Inventory aging in Inventory module; Warranty notifications in Customer Service module; Recall tracking in Compliance module
- **Key considerations:** Three distinct concerns should be separated. Warranty notification reuses the RECALL_NOTIFICATION table, which is a design coupling. The inventory aging calculation is simple date arithmetic. The recall completion logic includes automatic campaign closure.
- **Dependencies:** Depends on COMCKPL0. WARRANTY, RECALL_CAMPAIGN, and RECALL_VEHICLE tables drive processing.
