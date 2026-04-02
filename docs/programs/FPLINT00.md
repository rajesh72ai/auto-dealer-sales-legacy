# FPLINT00 — Floor Plan Interest Calculation

## Overview
- **Program ID:** FPLINT00
- **Module:** FPL
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FPLN
- **Source:** cbl/online/fpl/FPLINT00.cbl
- **Lines of Code:** 515
- **Complexity:** High

## Purpose
Calculates daily interest accrual for floor plan vehicles. Supports single VIN mode (online trigger) or batch mode (all active vehicles for a dealer). Updates FLOOR_PLAN_VEHICLE.INTEREST_ACCRUED and inserts FLOOR_PLAN_INTEREST daily detail records. Flags vehicles approaching curtailment (within 15 days).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Direct MFS message
- **MFS Output (MOD):** ASFPLN00
- **Message Format:** Input: mode (1: S=single, B=batch), VIN (17), dealer code (5). Output: mode, processed count, updated count, curtailment warnings, errors, total interest, message.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT | Fetch single VIN or cursor for all active |
| AUTOSALE.FLOOR_PLAN_VEHICLE | UPDATE | Update INTEREST_ACCRUED |
| AUTOSALE.FLOOR_PLAN_INTEREST | INSERT | Daily interest detail record |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMINTL0 | Daily interest calculation (DAY function) |
| COMFMTL0 | Currency formatting for total interest |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- **Single mode**: fetches one active floor plan by VIN, calculates and updates
- **Batch mode**: cursor iterates all active floor plans, optionally filtered by dealer
- Daily interest via COMINTL0 with DAY function: balance * rate / 365
- New accrued = existing accrued + daily interest
- Running total of all interest calculated in the run
- Each calculation inserts a FLOOR_PLAN_INTEREST detail record with: floor plan ID, date, daily balance, daily rate, daily interest, cumulative interest
- **Curtailment warning**: days to curtailment = DAYS(curtailment_date) - DAYS(current_date); warned if 0-15 days remaining
- Curtailment threshold configurable at 15 days (WS-CURTAIL-THRESHOLD)

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Error count tracked per-vehicle; processing continues on individual failures
- DB2 errors logged via COMDBEL0 but do not stop batch
- Summary output shows processed/updated/error counts
- IMS status checked after GU/ISRT

## Modernization Notes
- **Target Module:** vehicle (floor plan sub-module)
- **Target Endpoint:** POST /api/floor-plan/interest/accrue (batch), POST /api/floor-plan/vehicles/{vin}/interest (single)
- **React Page:** FloorPlanInterestAccrual
- **Key Considerations:** This is a classic batch-style job that runs as an online transaction -- in modern architecture, this should be a scheduled job/cron task. Daily interest = balance * (annual rate / 365) must use BigDecimal. The curtailment warning is a natural fit for an alerting/notification system. The FLOOR_PLAN_INTEREST detail table provides a full audit trail of daily accruals -- consider time-series storage. Error handling should be per-vehicle with a summary report.
