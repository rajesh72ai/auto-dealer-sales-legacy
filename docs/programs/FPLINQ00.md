# FPLINQ00 — Floor Plan Inquiry

## Overview
- **Program ID:** FPLINQ00
- **Module:** FPL
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FPLI
- **Source:** cbl/online/fpl/FPLINQ00.cbl
- **Lines of Code:** 462
- **Complexity:** Medium

## Purpose
Displays floor plan vehicles for a dealer with optional filters by VIN, status, or lender. Shows VIN, model description, floor date, days on floor, balance, calculated interest, and status for each vehicle. Calculates totals for balance and interest. Supports forward/backward paging (PF7/PF8) with 12 rows per page.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Direct MFS message
- **MFS Output (MOD):** ASFPLI00
- **Message Format:** Input: dealer code (5), VIN filter (17), status filter (2), lender filter (5), page action (1: F/B/space). Output: title, dealer code, detail rows (12), totals, page info, message.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT (cursor) | Retrieve floor plan records with filters |
| AUTOSALE.VEHICLE | JOIN | Vehicle details for model lookup |
| AUTOSALE.MODEL_MASTER | JOIN | Model name for display |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Currency formatting for balance and interest |
| COMINTL0 | Interest calculation for each vehicle |

### Key Business Logic
- Multi-table cursor join: FLOOR_PLAN_VEHICLE + VEHICLE + MODEL_MASTER
- Dynamic filtering: VIN, status, and lender filters applied via "OR parameter = default" pattern
- Ordered by floor date descending, then VIN
- Days on floor calculated via DB2: DAYS(CURRENT DATE) - DAYS(floor_date)
- Interest calculated per-vehicle via COMINTL0 (CALC function) using balance, rate, floor date to current date
- Paging: skip count = (page - 1) * 12; rows per page = 12
- Running totals for balance and interest across the page
- Currency formatting via COMFMTL0 for all monetary fields

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- WS-OUT-MESSAGE used as error flag
- DB2 cursor errors caught via EVALUATE on SQLCODE
- IMS status checked after GU/ISRT

## Modernization Notes
- **Target Module:** vehicle (floor plan sub-module)
- **Target Endpoint:** GET /api/floor-plan/vehicles?dealer={code}&vin={vin}&status={status}&lender={lender}&page={n}
- **React Page:** FloorPlanDashboard
- **Key Considerations:** The cursor-based paging maps to SQL LIMIT/OFFSET or keyset pagination. The real-time interest calculation per row should be a computed field in the API response. Consider server-side sorting and filtering. The multi-table join pattern should use an ORM or view. Days-on-floor and accrued interest are good candidates for computed/virtual columns.
