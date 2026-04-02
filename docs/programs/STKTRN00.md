# STKTRN00 — Inter-Dealer Stock Transfer

## Overview
- **Program ID:** STKTRN00
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKTRN00.cbl
- **Lines of Code:** 661
- **Complexity:** High

## Purpose
Dual-purpose screen for inter-dealer stock transfers. Supports creating transfer requests (VIN + destination dealer), listing pending transfers, and approving or rejecting pending transfers. On approval, triggers vehicle transfer-out process via COMSTCK0.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKT00
- **Message Format:** Input: action (RQST/LIST/APRV/REJT), dealer code, VIN, destination dealer, transfer ID. Output: action description, transfer detail lines (up to 12), new transfer ID.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Validate vehicle exists and is available |
| AUTOSALE.DEALER | SELECT | Validate destination dealer exists |
| AUTOSALE.STOCK_TRANSFER | INSERT | Create transfer request with status 'RQ' |
| AUTOSALE.STOCK_TRANSFER | SELECT (cursor) | List pending transfers for dealer |
| AUTOSALE.STOCK_TRANSFER | SELECT | Verify transfer exists for approve/reject |
| AUTOSALE.STOCK_TRANSFER | UPDATE | Set status to 'AP' (Approved) or 'RJ' (Rejected) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock count update (TRNO function on approve) |
| COMSEQL0 | Sequence number generation for transfer ID |
| COMLGEL0 | Audit logging |

### Key Business Logic
- Four actions: RQST (Request), LIST (List Pending), APRV (Approve), REJT (Reject).
- **Request:** Validates vehicle is AV status and assigned to requesting dealer. Cannot transfer to same dealer. Validates destination dealer exists. Generates transfer ID via COMSEQL0.
- **List:** Opens cursor for pending transfers (status 'RQ') where dealer is either from-dealer or to-dealer. Shows up to 12 rows.
- **Approve:** Verifies transfer is in 'RQ' status. Updates to 'AP' with approver and timestamp. Calls COMSTCK0 with 'TRNO' (transfer out) on source dealer.
- **Reject:** Updates to 'RJ' status. Only allows rejection of 'RQ' status transfers.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- DCLSTKTF
- DCLVEHCL

### Error Handling
- Invalid action returns error.
- Missing required fields per action produce specific error messages.
- Vehicle not found, not available, or not at dealer returns descriptive errors.
- Transfer not found or not pending returns error.

## Modernization Notes
- **Target Module:** vehicle (transfers)
- **Target Endpoint:** POST /api/transfers, GET /api/transfers?dealerCode=&status=pending, PUT /api/transfers/{id}/approve, PUT /api/transfers/{id}/reject
- **React Page:** StockDashboard
- **Key Considerations:** The four-action pattern should become separate REST endpoints. Transfer approval workflow could benefit from notifications. The COMSTCK0 integration should be replaced with event-driven stock updates.
