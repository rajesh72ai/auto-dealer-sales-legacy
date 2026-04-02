# STKALRT0 — Low Stock Alert Processor

## Overview
- **Program ID:** STKALRT0
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKALRT0.cbl
- **Lines of Code:** 339
- **Complexity:** Medium

## Purpose
Display-only query that scans STOCK_POSITION for all models where on-hand count is below the reorder point. Groups by dealer and shows model, on-hand, reorder point, deficit, and suggested order quantity. Supports filtering by dealer or querying all dealers.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKL00
- **Message Format:** Input: dealer code (optional, blank = all dealers). Output: alert count, up to 18 detail lines (dealer, model year, make, model, description, on-hand, reorder point, deficit, suggested quantity).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.STOCK_POSITION | SELECT (cursor) | Find models where ON_HAND_COUNT < REORDER_POINT |
| AUTOSALE.MODEL_MASTER | JOIN | Get model name/description |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Field formatting |
| COMMSGL0 | Message builder for warning messages |

### Key Business Logic
- Dealer code is optional; blank means all dealers.
- Cursor selects stock positions where ON_HAND_COUNT < REORDER_POINT.
- Deficit = REORDER_POINT - ON_HAND_COUNT.
- Suggested order quantity = deficit + safety stock (constant = 2 units).
- Minimum suggested quantity is 1.
- Results ordered by dealer, make, model.
- Maximum 18 detail lines displayed.
- Uses COMMSGL0 to build warning-severity info message.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- DB2 cursor errors set error message.
- "NO LOW STOCK ALERTS" if all models are above reorder point.

## Modernization Notes
- **Target Module:** vehicle (stock alerts)
- **Target Endpoint:** GET /api/stock/alerts?dealerCode=
- **React Page:** StockDashboard
- **Key Considerations:** Safety stock constant should be configurable per dealer/model. The 18-row limit should become paginated. Could be enhanced with push notifications in the modernized system.
