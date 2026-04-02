# SALCAN00 — Sale Cancellation / Unwind

## Overview
- **Program ID:** SALCAN00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALX
- **Source:** cbl/online/sal/SALCAN00.cbl
- **Lines of Code:** 687
- **Complexity:** High

## Purpose
Handles the cancellation or unwinding of a completed or in-progress sale. Performs comprehensive reversal of all deal-related operations: reverses vehicle sold status back to available, restores stock position counts, decrements incentive units used, reverses floor plan payoff if applicable, and updates the deal status to CA (Cancelled) or UW (Unwound). Creates detailed audit trail for each reversal action.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLCN00 (Cancellation Response)
- **Message Format:** Input includes deal number (10) and cancellation reason (200). Output shows deal header, previous and new status, a list of up to 8 reversal actions performed (numbered with descriptions), and the cancellation reason.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Read deal details and current status |
| AUTOSALE.SALES_DEAL | UPDATE | Update status to CA or UW |
| AUTOSALE.VEHICLE | SELECT + UPDATE | Reverse vehicle status from SD to AV |
| AUTOSALE.STOCK_POSITION | UPDATE (via COMSTCK0) | Reverse stock counts (RECV function) |
| AUTOSALE.INCENTIVE_APPLIED | SELECT (cursor) | Find applied incentives for reversal |
| AUTOSALE.INCENTIVE_APPLIED | DELETE | Remove applied incentive records |
| AUTOSALE.INCENTIVE_PROGRAM | UPDATE | Decrement UNITS_USED for reversed incentives |
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT + UPDATE | Reverse floor plan payoff if applicable |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock update — RECV function to reverse sold status |
| COMLGEL0 | Audit log entry for each reversal action |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Pre-cancellation validation:** Deal must exist and not already be cancelled (CA) or unwound (UW).
- **Status determination:** If deal was in DL (Delivered) status, new status is UW (Unwound); otherwise CA (Cancelled).
- **Vehicle reversal:** If vehicle was marked SD (Sold), reverses to AV (Available) and calls COMSTCK0 with RECV function to adjust stock position (increment on-hand, decrement sold counts).
- **Incentive reversal:** Opens cursor CSR_INC_REVERSE to find all incentives applied to the deal. For each: decrements UNITS_USED on INCENTIVE_PROGRAM and deletes the INCENTIVE_APPLIED record.
- **Floor plan reversal:** Checks if a floor plan payoff record exists. If so, reverses the payoff status.
- **Reversal tracking:** Each reversal action is numbered (up to 8) and described in the output for visibility.
- **Comprehensive audit:** Each individual reversal action is logged separately via COMLGEL0.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLINAPP — DCLGEN for INCENTIVE_APPLIED table

### Error Handling
Uses WS-RETURN-CODE pattern. Each reversal step has its own error handling — if one step fails, the error is logged but processing continues for remaining reversals. DB errors via COMDBEL0.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** POST /api/deals/{dealNumber}/cancel
- **React Page:** DealCancellation
- **Key Considerations:** This is a complex compensating transaction that should be implemented as a saga pattern in the modern system. Each reversal step (vehicle, stock, incentives, floor plan) should be an individual service call within a transaction coordinator. The "continue on error" behavior for individual reversal steps needs careful consideration — in a modern system, this might be implemented as a partial rollback with error reporting. The comprehensive audit trail is mandatory for compliance. Idempotency is critical to prevent double-reversal.
