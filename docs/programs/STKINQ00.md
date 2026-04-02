# STKINQ00 — Stock Position Inquiry

## Overview
- **Program ID:** STKINQ00
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKINQ00.cbl
- **Lines of Code:** 405
- **Complexity:** Medium

## Purpose
Displays stock position for a dealer with optional filters by model year, make, model, and status. Joins MODEL_MASTER for description. Shows low stock alert flag when ON_HAND < REORDER_POINT.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKI00
- **Message Format:** Input: dealer code (required), model year, make, model, status filter. Output: up to 15 stock position detail lines (model year, make, model, description, on-hand, in-transit, allocated, on-hold, sold MTD/YTD, reorder point, alert flag).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.STOCK_POSITION | SELECT (cursor) | Read stock positions for dealer |
| AUTOSALE.MODEL_MASTER | JOIN | Get model name/description |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Currency formatting |
| COMMSGL0 | Message builder for error messages |

### Key Business Logic
- Dealer code is required. Model year, make, model, and status are optional filters.
- Model year converted from alpha to numeric; zero means "all years".
- Uses OR-based optional parameter pattern in cursor WHERE clause.
- Results ordered by model year DESC, make, model.
- Up to 15 rows displayed per page.
- Low stock alert: if ON_HAND < REORDER_POINT, displays "*LOW*" flag.
- Error messages formatted via COMMSGL0 with severity 'E'.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- DCLSTKPS
- DCLMODEL

### Error Handling
- Dealer code blank returns error.
- DB2 cursor errors produce error messages.
- "NO STOCK POSITION RECORDS FOUND" if no rows match.

## Modernization Notes
- **Target Module:** vehicle (stock)
- **Target Endpoint:** GET /api/stock/positions/{dealerCode}?year=&make=&model=&status=
- **React Page:** StockDashboard
- **Key Considerations:** The 15-row limit should become proper pagination. Optional filter pattern maps directly to query parameters. Low stock alert flag can be computed client-side or via a computed column.
