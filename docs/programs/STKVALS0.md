# STKVALS0 — Stock Valuation Report

## Overview
- **Program ID:** STKVALS0
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKVALS0.cbl
- **Lines of Code:** 528
- **Complexity:** High

## Purpose
Calculates total floor plan exposure for a dealer. Groups inventory by category (New, Demo, Loaner, On Hold, Other). Shows count, total invoice value, total MSRP, average age, and estimated holding cost. Joins Vehicle, Price_Master, and Floor_Plan_Vehicle for interest accrual data.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKV00
- **Message Format:** Input: dealer code. Output: 5 category lines (name, count, invoice, MSRP, avg age, holding cost), totals line, floor plan interest total.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT (cursor) | Read all inventory vehicles for dealer |
| AUTOSALE.PRICE_MASTER | JOIN | Get invoice price and MSRP |
| AUTOSALE.FLOOR_PLAN_VEHICLE | LEFT JOIN | Get accrued interest for active floor plans |
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT SUM | Total floor plan interest for dealer |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMPRCL0 | Vehicle pricing engine |
| COMFMTL0 | Currency formatting for all monetary values |

### Key Business Logic
- Dealer code is required.
- 5 categories based on vehicle status: AV (New), DM (Demo), LN (Loaner), HD (On Hold), OT (Other/Allocated).
- Cursor fetches vehicles with status AV, DM, LN, HD, or AL.
- Estimated holding cost = invoice price * daily hold rate (0.000164) * days in stock.
- Daily hold rate represents estimated floor plan interest rate per day.
- Floor plan interest accrued retrieved separately via SUM query on FLOOR_PLAN_VEHICLE where FP_STATUS='AC'.
- Grand totals include total count, invoice, MSRP, average age, and total holding cost.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Dealer code blank returns error.
- DB2 cursor errors produce error messages.

## Modernization Notes
- **Target Module:** vehicle (financial analytics)
- **Target Endpoint:** GET /api/stock/valuation/{dealerCode}
- **React Page:** StockDashboard
- **Key Considerations:** Daily hold rate should be configurable per dealer/floor plan provider. Floor plan integration is critical financial data. MSRP vs invoice spread analysis could be enhanced. This is a read-only analytics endpoint.
