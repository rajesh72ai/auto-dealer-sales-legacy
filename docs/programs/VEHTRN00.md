# VEHTRN00 — Dealer-to-Dealer Vehicle Transfer

## Overview
- **Program ID:** VEHTRN00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHTR
- **Source:** cbl/online/veh/VEHTRN00.cbl
- **Lines of Code:** 950
- **Complexity:** High

## Purpose
Manages inter-dealer vehicle transfers through a complete lifecycle: request, approve, reject, and complete. Salesperson at from-dealer initiates request, manager at to-dealer approves/rejects. On approval, vehicle status changes to TR (Transfer) and stock counts updated at source dealer. On completion (arrival), status changes to AV at new dealer with stock updates at both dealers.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT)
- **MFS Output (MOD):** (via WSMSGFMT)
- **Message Format:** Input: function (RQ=Request/AP=Approve/RJ=Reject/CM=Complete/IQ=Inquiry), VIN, from-dealer, to-dealer, transfer ID. Output: transfer details, vehicle info, status changes.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Validate vehicle status and dealer |
| AUTOSALE.VEHICLE | UPDATE | Change dealer code and status on approve/complete |
| AUTOSALE.STOCK_TRANSFER | INSERT | Create transfer request |
| AUTOSALE.STOCK_TRANSFER | SELECT | Verify transfer for approve/reject/complete |
| AUTOSALE.STOCK_TRANSFER | UPDATE | Update transfer status |
| AUTOSALE.VEHICLE_STATUS_HIST | INSERT | Record status changes |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock count update (TRNO on approve, TRNI on complete) |
| COMLGEL0 | Audit log entry |
| COMSEQL0 | Sequence number generation for transfer ID |

### Key Business Logic
- Five functions: RQ (Request), AP (Approve), RJ (Reject), CM (Complete), IQ (Inquiry).
- **Request:** Vehicle must be AV and at requesting dealer. Creates STOCK_TRANSFER with status 'RQ'.
- **Approve:** Updates transfer to 'AP'. Updates vehicle status to 'TR'. Calls COMSTCK0 'TRNO' (transfer out) at source dealer. Records status history.
- **Reject:** Updates transfer to 'RJ'. Vehicle status unchanged.
- **Complete:** Updates transfer to 'CM'. Updates vehicle dealer code to destination. Updates vehicle status to 'AV'. Calls COMSTCK0 'TRNI' (transfer in) at destination dealer. Records status history.
- **Inquiry:** Displays transfer and vehicle details.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLVEHCL
- DCLSTKTF
- DCLVHSTH

### Error Handling
- Invalid function returns error.
- Vehicle not available or not at dealer returns error.
- Transfer not found or wrong status returns error.
- COMSTCK0 failures generate warnings but transfer proceeds.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/transfers, PUT /api/transfers/{id}/approve, PUT /api/transfers/{id}/reject, PUT /api/transfers/{id}/complete
- **React Page:** VehicleSearch
- **Key Considerations:** This is functionally similar to STKTRN00 but from the vehicle perspective. Consider consolidating into a single transfer service. The multi-step workflow (request->approve->complete) maps well to a state machine. Notifications should be added for approval requests.
