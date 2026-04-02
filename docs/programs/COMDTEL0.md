# COMDTEL0 — Date/Time Utility Module

## Overview
- **Program ID:** COMDTEL0
- **Type:** Common Module
- **Source:** cbl/common/COMDTEL0.cbl
- **Lines of Code:** 748
- **Complexity:** Medium

## Purpose
Provides common date functions used across all AUTOSALES programs: Julian-to-Gregorian conversion, Gregorian-to-Julian conversion, days-between calculation, business day addition (skipping weekends), age calculation from a date to today, and current date/time retrieval in multiple formats.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMDTEL0' USING LK-DTU-FUNCTION LK-DTU-INPUT-AREA LK-DTU-OUTPUT-AREA LK-DTU-RETURN-CODE LK-DTU-ERROR-MSG`.

Function codes: JULG, GJUL, DAYS, BDAY, AGED, CURR.

### Database Access
None.

### Called Subroutines
None (uses COBOL intrinsic functions only).

### Key Business Logic
- **JULG (Julian to Gregorian):** Converts YYYYDDD to YYYY-MM-DD using a month-days table with leap year adjustment.
- **GJUL (Gregorian to Julian):** Converts YYYY-MM-DD to YYYYDDD by accumulating days through preceding months.
- **DAYS (Days Between):** Uses FUNCTION INTEGER-OF-DATE to convert both dates, then subtracts. Signed result (date2 - date1).
- **BDAY (Business Days):** Adds/subtracts business days one at a time, skipping Saturday (DOW=6) and Sunday (DOW=7). Supports negative days for backward calculation.
- **AGED (Age Calculation):** Computes total days, years, months, and remaining days from input date to today. Adjusts for negative months/days.
- **CURR (Current DateTime):** Returns current date in YYYY-MM-DD, CCYYMMDD, MM/DD/YYYY, HH:MM:SS, DB2 timestamp, Julian, day-of-week (name and number) formats.
- **Leap year:** Divisible by 4, except centuries, unless also divisible by 400.
- **Date validation:** Year range 1900-2099, month 01-12, day validated per month including leap year February.

### Copybooks Used
None.

### Input/Output
- **Input:** Function code, up to two dates, Julian date, days count, format code
- **Output:** Gregorian date, CCYYMMDD, MM/DD/YYYY, Julian date, days count, DOW, timestamp, time, years/months/days

## Modernization Notes
- **Target:** Standard date/time library functions (java.time, moment.js, etc.)
- **Key considerations:** All functions map directly to standard library calls in modern languages. The business-day calculation is the only non-trivial function that may need a custom implementation (and may need holiday support in the future).
- **Dependencies:** Used system-wide for date formatting and arithmetic. No external dependencies.
