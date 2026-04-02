# FPLRPT00 — Floor Plan Exposure Report

## Overview
- **Program ID:** FPLRPT00
- **Module:** FPL
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FPLR
- **Source:** cbl/online/fpl/FPLRPT00.cbl
- **Lines of Code:** 595
- **Complexity:** High

## Purpose
Summarizes floor plan liability for a dealer: total balance, total interest, grouped by lender. Groups by new/used vehicle condition, lender, and age bucket (0-30, 31-60, 61-90, 91+ days). Calculates weighted average interest rate and average days on floor.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Direct MFS message
- **MFS Output (MOD):** ASFPLR00
- **Message Format:** Input: dealer code (5). Output: lender summaries (up to 8), age buckets, new/used split, grand totals (vehicles, balance, interest, weighted avg rate, avg days).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT (cursor) | Active floor plans for dealer |
| AUTOSALE.VEHICLE | JOIN | Vehicle condition (new/used) |
| AUTOSALE.LENDER | JOIN | Lender name |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Currency and percentage formatting |
| COMINTL0 | Interest calculation (referenced but primary calc is via accrued field) |

### Key Business Logic
- Cursor joins FLOOR_PLAN_VEHICLE + VEHICLE + LENDER for active vehicles (status='AC')
- **Lender accumulation**: up to 8 lenders tracked with vehicle count, balance, interest, rate numerator, total days
- **Weighted average rate**: sum(balance * rate) / sum(balance)
- **Average days on floor**: sum(days) / total vehicles
- **Age buckets**: 0-30 days, 31-60, 61-90, 91+ based on DAYS(current) - DAYS(floor_date)
- **New/used split**: based on VEHICLE.VEHICLE_CONDITION ('N' vs other)
- **Per-lender stats**: vehicle count, total balance, total interest, average rate, average days
- Grand totals: total vehicles, total balance, total interest, weighted avg rate, average days
- Formatting via COMFMTL0: CUR function for currency, PCT function for percentages

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- WS-OUT-MESSAGE used as error flag
- Cursor open/fetch errors caught
- If no active vehicles found, informational message returned
- IMS status checked after GU/ISRT

## Modernization Notes
- **Target Module:** vehicle (floor plan sub-module)
- **Target Endpoint:** GET /api/floor-plan/reports/exposure?dealer={code}
- **React Page:** FloorPlanExposureReport
- **Key Considerations:** This is an analytics/reporting endpoint -- consider using aggregate SQL queries instead of cursor-based accumulation. The weighted average rate calculation is a common financial metric that must use precise decimal arithmetic. The age bucket concept maps well to dashboard charts. The 8-lender limit is an artificial COBOL constraint that should be removed. Consider caching for performance since this is a read-only report.
