# STKSUM00 — Stock Summary Dashboard

## Overview
- **Program ID:** STKSUM00
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKSUM00.cbl
- **Lines of Code:** 422
- **Complexity:** Medium

## Purpose
Aggregates stock position by body style for a given dealer. Shows counts for sedans, SUVs, trucks, coupes, etc. Calculates total inventory count, total estimated value (invoice), and average days in stock.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKS00
- **Message Format:** Input: dealer code. Output: up to 10 body style lines (description, count, value), totals line (total count, total value, average days).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.STOCK_POSITION | SELECT (cursor) | Aggregate stock by body style |
| AUTOSALE.MODEL_MASTER | JOIN | Get body style code |
| AUTOSALE.PRICE_MASTER | JOIN | Get invoice price for value |
| AUTOSALE.VEHICLE | LEFT JOIN | Get average days in stock |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Currency formatting for values |

### Key Business Logic
- Dealer code is required.
- 10 body style categories: SD (Sedans), SV (SUV/Crossover), TK (Trucks), CP (Coupes), CV (Convertibles), VN (Vans/Minivan), WG (Wagons), HB (Hatchbacks), EV (E-Vehicles), OT (Other).
- Cursor aggregates with SUM(ON_HAND_COUNT), SUM(ON_HAND_COUNT * INVOICE_PRICE), AVG(DAYS_IN_STOCK).
- Unmapped body styles default to "Other" (index 10).
- Only body styles with count > 0 are output.
- Grand totals: total count, total value, average days across all body styles.
- All currency values formatted via COMFMTL0.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Dealer code blank returns error.
- DB2 cursor errors produce error messages.

## Modernization Notes
- **Target Module:** vehicle (stock analytics)
- **Target Endpoint:** GET /api/stock/summary/{dealerCode}
- **React Page:** StockDashboard
- **Key Considerations:** Body style mapping should be data-driven rather than hard-coded. Average days calculation can be done entirely in SQL. This is a read-only analytics endpoint ideal for caching.
