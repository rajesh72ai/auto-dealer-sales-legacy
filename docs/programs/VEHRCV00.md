# VEHRCV00 — Vehicle Receiving / Check-In

## Overview
- **Program ID:** VEHRCV00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHRC
- **Source:** cbl/online/veh/VEHRCV00.cbl
- **Lines of Code:** 736
- **Complexity:** High

## Purpose
Dealer receives vehicle at dock. Scans VIN, inspects vehicle, captures stock number (auto or manual), lot location, odometer, damage info, and key number. Validates VIN and verifies vehicle is expected at this dealer. Updates status to AV (Available). Triggers PDI scheduling via insert into PDI_SCHEDULE.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT)
- **MFS Output (MOD):** (via WSMSGFMT)
- **Message Format:** Input: function (RC=Receive/IQ=Inquiry), VIN, dealer code, stock number, stock mode (A=Auto/M=Manual), lot location, odometer, damage flag/description, key number. Output: vehicle details, receiving status, PDI schedule date and ID.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Verify vehicle exists, get current status |
| AUTOSALE.VEHICLE | UPDATE | Set status AV, dealer, lot, stock#, receive date, odometer, damage, key |
| AUTOSALE.VEHICLE_STATUS_HIST | SELECT MAX | Get next history sequence |
| AUTOSALE.VEHICLE_STATUS_HIST | INSERT | Record status change to AV |
| AUTOSALE.PDI_SCHEDULE | INSERT | Schedule pre-delivery inspection |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN validation |
| COMVINL0 | VIN decode/lookup |
| COMSTCK0 | Stock update (RECV function) |
| COMSEQL0 | Sequence number generation for stock number and PDI ID |
| COMLGEL0 | Audit log entry |

### Key Business Logic
- VIN validated via COMVALD0 and decoded via COMVINL0.
- Vehicle must exist in VEHICLE table and be in status AL (Allocated), IT (In Transit), or PR (Produced).
- Warning if vehicle is assigned to a different dealer than the receiving dealer.
- Stock number auto-generated via COMSEQL0 if stock mode is 'A' or stock number is blank.
- Damage flag defaults to 'N' if blank. Damage description nullable.
- Odometer must be numeric.
- Vehicle updated to status 'AV' with receive date = current date, DAYS_IN_STOCK = 0.
- Status history record inserted with "VEHICLE RECEIVED AT DEALER DOCK" reason.
- PDI scheduled with 42 checklist items, status 'SC' (Scheduled).
- Stock counts updated via COMSTCK0 with 'RECV' function.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLVEHCL
- DCLVHSTH
- DCLPDISH

### Error Handling
- VIN validation failure returns COMVALD0 error message.
- Vehicle not found returns error.
- Wrong dealer generates warning (RC=4) but continues.
- Invalid status returns error with current status.
- Stock number generation failure returns error.
- PDI schedule insert failure generates warning but doesn't fail receiving.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/{vin}/receive
- **React Page:** VehicleSearch
- **Key Considerations:** This is a critical dock operation often done on mobile devices. Auto stock number generation should be a configurable dealer preference. PDI scheduling should be event-driven. Damage documentation could include photo upload in the modernized system.
