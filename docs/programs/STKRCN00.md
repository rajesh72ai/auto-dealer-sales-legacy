# STKRCN00 — Stock Reconciliation

## Overview
- **Program ID:** STKRCN00
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKRCN00.cbl
- **Lines of Code:** 522
- **Complexity:** High

## Purpose
Lists each model with system count (from STOCK_POSITION) vs physical count (user entered). Calculates variance per model and total. PF5=Accept creates STOCK_ADJUSTMENT records. PF6=Print formats reconciliation report.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKR00
- **Message Format:** Input: dealer code, reconciliation date, PF key, up to 20 physical count entries (model year, make, model, count). Output: up to 20 detail lines (model, system count, physical count, variance, flag), total variance.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.STOCK_POSITION | SELECT (cursor) | Read system on-hand counts per model |
| AUTOSALE.STOCK_POSITION | UPDATE | Update ON_HAND_COUNT to physical count |
| AUTOSALE.MODEL_MASTER | JOIN | Get model description |
| AUTOSALE.STOCK_ADJUSTMENT | SELECT MAX | Get next adjustment ID |
| AUTOSALE.STOCK_ADJUSTMENT | INSERT | Record physical count adjustment |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Dealer code and reconciliation date are required.
- Three modes: display (default), accept (PF5), print (PF6).
- Display mode loads system counts from STOCK_POSITION for up to 20 models.
- Accept mode: compares user-entered physical counts against system counts, computes variance (physical - system), flags non-zero variances with 'ADJ', creates STOCK_ADJUSTMENT records of type 'PH' (Physical Count), and updates STOCK_POSITION.ON_HAND_COUNT.
- Total variance accumulated across all models.
- Print mode loads current data and formats for printing.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- DCLSTKPS
- DCLSTKAJ
- DCLMODEL

### Error Handling
- Missing dealer/date returns error.
- DB2 cursor errors invoke COMDBEL0.
- "NO STOCK POSITION RECORDS FOUND" if no data for dealer.

## Modernization Notes
- **Target Module:** vehicle (stock operations)
- **Target Endpoint:** GET /api/stock/reconciliation/{dealerCode}, POST /api/stock/reconciliation/{dealerCode}/accept
- **React Page:** StockDashboard
- **Key Considerations:** The PF-key driven multi-mode pattern should become separate API endpoints. Physical counts could be entered via mobile device. Reconciliation acceptance should be an atomic transaction.
