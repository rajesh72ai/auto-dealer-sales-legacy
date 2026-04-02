# BATDLY00 — Daily End-of-Day Processing

## Overview
- **Program ID:** BATDLY00
- **Type:** Batch
- **Source:** cbl/batch/BATDLY00.cbl
- **Lines of Code:** 657
- **Complexity:** High

## Purpose
Nightly end-of-day batch that performs three critical business functions: updates vehicle status for delivered vehicles (STOCK to SOLD), expires pending deals older than 30 days, and calculates daily floor plan interest accrual for all active floor plan vehicles.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Three-phase processing with shared checkpoint logic.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT/UPDATE | Read delivered vehicles, update status to SOLD |
| AUTOSALE.SALES_DEAL | SELECT/UPDATE | Read pending deals for expiry, update status to CA |
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT/UPDATE | Read active floor plans, update accrued interest and days |
| AUTOSALE.FLOOR_PLAN_LENDER | SELECT | Read lender base rate and spread |
| AUTOSALE.FLOOR_PLAN_INTEREST | INSERT | Insert daily interest calculation records |
| AUTOSALE.RESTART_CONTROL | READ/UPDATE | Checkpoint/restart via COMCKPL0 |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management (INIT/CHKP/DONE functions) |
| COMLGEL0 | Audit logging for status changes |

### Key Business Logic
- **Phase 1 - Delivered Vehicles:** Joins VEHICLE and SALES_DEAL to find vehicles delivered today still in stock status. Updates VEHICLE_STATUS to 'SD' (Sold).
- **Phase 2 - Expire Pending Deals:** Selects deals in status WS/NE/PA with DEAL_DATE <= 30 days ago. Updates DEAL_STATUS to 'CA' (Cancelled).
- **Phase 3 - Floor Plan Interest:** Joins FLOOR_PLAN_VEHICLE with FLOOR_PLAN_LENDER for active vehicles. Calculates: COMBINED_RATE = BASE_RATE + SPREAD; DAILY_RATE = COMBINED_RATE / 365; DAILY_INTEREST = BALANCE * DAILY_RATE / 100; CUMULATIVE = prior accrued + daily. Inserts record into FLOOR_PLAN_INTEREST and updates the vehicle's accrued interest and days counter.
- **Checkpointing:** Every 500 records across all phases.

### Copybooks Used
- WSCKPT00
- WSRSTCTL
- SQLCA

### Input/Output
- **Input:** DB2 tables only (no file input)
- **Output:** DB2 table updates/inserts, DISPLAY statements to SYSOUT

## Modernization Notes
- **Target:** Scheduled jobs in the Inventory Management and Finance modules
- **Key considerations:** Three distinct functions should likely be separated into independent microservices or scheduled tasks. The interest calculation formula (BALANCE * (BASE+SPREAD) / 365 / 100) is a core business rule that must be preserved exactly.
- **Dependencies:** Depends on COMCKPL0, COMLGEL0. Floor plan lender configuration drives interest rates.
