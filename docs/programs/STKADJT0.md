# STKADJT0 — Stock Adjustment Entry

## Overview
- **Program ID:** STKADJT0
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKADJT0.cbl
- **Lines of Code:** 473
- **Complexity:** High

## Purpose
Allows manual stock adjustments for a vehicle. Supports adjustment types: DM (Damage), WO (Write-Off), RC (Reclassify), PH (Physical Count), OT (Other). Updates vehicle status, inserts a STOCK_ADJUSTMENT record, and updates STOCK_POSITION counts via COMSTCK0.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKA00
- **Message Format:** Input: dealer code, VIN, adjustment type, reason. Output: vehicle info, adjustment type description, old/new status, adjustment ID.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Verify vehicle exists, get current status |
| AUTOSALE.VEHICLE | UPDATE | Change vehicle status if adjustment requires it |
| AUTOSALE.STOCK_ADJUSTMENT | SELECT MAX | Get next adjustment ID |
| AUTOSALE.STOCK_ADJUSTMENT | INSERT | Record the adjustment |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock count update (SOLD function for DM/WO to decrement counts) |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Dealer code, VIN, valid adjustment type, and reason text are all required.
- Adjustment types validated against table: DM, WO, RC, PH, OT.
- New vehicle status determined by adjustment type: DM->DG (Damaged), WO->WO (Write-Off), RC->AV (Available), PH/OT->no change.
- Vehicle status updated only if new status differs from current.
- For DM and WO adjustments, COMSTCK0 called with 'SOLD' function to decrement on-hand count.
- Adjustment record includes old status, new status, adjusted-by user ID from IO-PCB.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- DCLVEHCL
- DCLSTKAJ

### Error Handling
- IMS GU failure produces error message.
- Vehicle not found returns "VEHICLE NOT FOUND FOR SPECIFIED VIN".
- DB2 errors call COMDBEL0 with SQLCA, program, section, table, and operation context.
- Warning generated if vehicle status update fails but adjustment inserted.

## Modernization Notes
- **Target Module:** vehicle (stock operations)
- **Target Endpoint:** POST /api/stock/adjustments
- **React Page:** StockDashboard
- **Key Considerations:** The adjustment-to-status mapping logic should be centralized. COMSTCK0 integration needs to be replaced with direct stock position service calls. The MAX(ADJUST_ID)+1 pattern should be replaced with auto-increment.
