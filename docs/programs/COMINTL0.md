# COMINTL0 — Floor Plan Interest Calculation

## Overview
- **Program ID:** COMINTL0
- **Type:** Common Module
- **Source:** cbl/common/COMINTL0.cbl
- **Lines of Code:** 628
- **Complexity:** High

## Purpose
Calculates daily interest for floor plan vehicles supporting multiple day-count conventions (30/360, Actual/365, Actual/Actual). Determines curtailment status and cumulative interest from floor date. Can optionally insert interest records into DB2.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMINTL0' USING LS-INT-REQUEST LS-INT-RESULT`.

Function codes: DALY (daily interest), RNGE (range interest), CUML (cumulative from floor date).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FLOOR_PLAN_INTEREST | INSERT | Insert calculated interest record (CUML function only, when floor plan ID provided) |

### Called Subroutines
None.

### Key Business Logic
- **Day count conventions:** 30/360 (divisor=360), Actual/365 (divisor=365), Actual/Actual (divisor=365 or 366 for leap years).
- **Daily rate:** ANNUAL_RATE / DAY_COUNT_DIVISOR / 100.
- **Daily interest:** PRINCIPAL * DAILY_RATE.
- **Range interest:** DAILY_INTEREST * days in range (last calc date to calc date).
- **Cumulative interest:** DAILY_INTEREST * days since floor date (simplified, assumes constant balance).
- **Curtailment:** New vehicles = 90 days, Used vehicles = 60 days. If days on floor exceeds limit (or past explicit curtailment date), sets curtail flag and calculates days past curtailment.
- **Validation:** Principal must be > 0, rate must be > 0 and <= 25%, calc date required, day count basis validated.
- **Date arithmetic:** Converts YYYY-MM-DD dates to integer dates via FUNCTION INTEGER-OF-DATE for day calculations.

### Copybooks Used
- WSSQLCA
- DCLFPVEH (FLOOR_PLAN_VEHICLE DCLGEN)
- DCLFPINT (FLOOR_PLAN_INTEREST DCLGEN)
- WSFPL000 (Floor plan working storage)

### Input/Output
- **Input:** Principal balance, annual rate, calc date, last calc date, floor date, curtailment date, day count basis, vehicle type, floor plan ID
- **Output:** Daily rate, daily interest, days accrued, cumulative interest, days on floor, curtailment flag, days past curtailment, period interest, SQLCODE

## Modernization Notes
- **Target:** Finance calculation engine / Floor Plan Interest service
- **Key considerations:** The day-count conventions and curtailment rules are critical financial calculations. The three calculation modes (daily/range/cumulative) serve different use cases. The DB2 insert side-effect in CUML mode should be separated from the calculation logic.
- **Dependencies:** Called by BATDLY00 (daily processing). FLOOR_PLAN_INTEREST table for persistence.
