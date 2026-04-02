# VEHUPD00 — Vehicle Status Update

## Overview
- **Program ID:** VEHUPD00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHUP
- **Source:** cbl/online/veh/VEHUPD00.cbl
- **Lines of Code:** 613
- **Complexity:** High

## Purpose
Allows manual status change with reason code. Validates status transitions (e.g., cannot go from SD back to AV without unwind). Inserts VEHICLE_STATUS_HIST record for audit trail. Notifies stock module of status change via COMSTCK0.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT)
- **MFS Output (MOD):** (via WSMSGFMT)
- **Message Format:** Input: function (UP=Update/IQ=Inquiry), VIN, new status, reason. Output: VIN, stock number, year/make/model, old status >> new status, reason, valid transition reference table.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Get current vehicle data and status |
| AUTOSALE.VEHICLE | UPDATE | Apply new status |
| AUTOSALE.VEHICLE_STATUS_HIST | SELECT MAX | Get next history sequence |
| AUTOSALE.VEHICLE_STATUS_HIST | INSERT | Record status change with reason |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock update with appropriate function per transition |
| COMLGEL0 | Audit log entry |

### Key Business Logic
- Two modes: UP (Update) and IQ (Inquiry).
- Valid status codes: PR, AL, IT, DL, AV, HD, SD, TR, SV, WO, RJ.
- Reason is required for status change.
- **Status transition rules:**
  - PR -> AL, IT
  - AL -> DL, AV, IT
  - IT -> DL, AV
  - DL -> AV
  - AV -> HD, SD, TR, SV
  - HD -> AV
  - TR -> AV (at new dealer)
  - SV -> AV
  - SD -> requires deal unwind (blocked)
  - ANY -> WO, RJ (manager override)
- COMSTCK0 function mapped per transition: AL->ALOC, to AV->RECV, HD->HOLD, AV->SD->SOLD, TR->TRNO, HD->AV->RLSE, TR->AV->TRNI.
- Display output includes valid transition reference table for user guidance.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLVEHCL
- DCLVHSTH

### Error Handling
- VIN required. New status and reason required for update.
- Unrecognized status code returns error.
- Invalid transition returns descriptive error with from/to status.
- SD status blocks return without unwind.
- DB2 errors on update return error.
- COMSTCK0 failures generate warning but status change persists.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** PUT /api/vehicles/{vin}/status
- **React Page:** VehicleSearch
- **Key Considerations:** The status transition matrix is core business logic that should be extracted into a state machine service. The transition rules should be configurable. The WO/RJ override for managers needs role-based access control. The COMSTCK0 function mapping should be centralized.
