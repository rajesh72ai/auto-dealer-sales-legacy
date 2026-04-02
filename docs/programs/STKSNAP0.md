# STKSNAP0 — Daily Stock Snapshot

## Overview
- **Program ID:** STKSNAP0
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKSNAP0.cbl
- **Lines of Code:** 500
- **Complexity:** High

## Purpose
Captures point-in-time stock position for historical tracking. Reads all STOCK_POSITION records for each dealer, calculates average days in stock per model (from VEHICLE table) and total value per model (count * invoice price). Inserts into STOCK_SNAPSHOT with current date. Usually run end-of-day but available online.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKN00
- **Message Format:** Input: dealer code (optional, blank = all dealers), snapshot date. Output: records read/inserted/deleted counts, total on-hand/in-transit/on-hold, total value.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.STOCK_POSITION | SELECT (cursor) | Read stock positions with avg days and value |
| AUTOSALE.VEHICLE | LEFT JOIN | Calculate average days in stock per model |
| AUTOSALE.PRICE_MASTER | JOIN | Get invoice price for value calculation |
| AUTOSALE.STOCK_SNAPSHOT | DELETE | Remove existing snapshot for date/dealer |
| AUTOSALE.STOCK_SNAPSHOT | INSERT | Insert new snapshot rows |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Audit logging |
| COMFMTL0 | Currency formatting for total value |

### Key Business Logic
- Dealer code optional (blank = all dealers). Snapshot date defaults to current date if not provided.
- Deletes existing snapshot for the same date/dealer before creating new one.
- Complex cursor joins STOCK_POSITION with PRICE_MASTER and left-joins VEHICLE for average days in stock.
- Vehicles in status AV, DM, LN, HD considered for average days calculation.
- Total value = ON_HAND_COUNT * INVOICE_PRICE.
- Accumulates totals for on-hand, in-transit, on-hold, and total value across all snapshot rows.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- DCLSTKSS

### Error Handling
- DB2 errors on delete, cursor, or insert call COMDBEL0.
- Cursor fetch errors stop processing with error message.

## Modernization Notes
- **Target Module:** vehicle (stock analytics)
- **Target Endpoint:** POST /api/stock/snapshots
- **React Page:** StockDashboard
- **Key Considerations:** This is a batch-like operation that should become a scheduled job or triggered process. The delete-then-insert pattern should be replaced with an upsert or versioned snapshot. Historical data is valuable for analytics dashboards.
