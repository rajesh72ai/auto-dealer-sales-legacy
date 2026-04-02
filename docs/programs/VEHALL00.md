# VEHALL00 — Vehicle Allocation from Manufacturer

## Overview
- **Program ID:** VEHALL00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHAL
- **Source:** cbl/online/veh/VEHALL00.cbl
- **Lines of Code:** 639
- **Complexity:** High

## Purpose
Receives allocation data from the production system. Assigns produced vehicles to dealer orders based on priority and region. Updates PRODUCTION_ORDER.ALLOCATED_DEALER and VEHICLE.DEALER_CODE fields. Changes vehicle status from PR (Produced) to AL (Allocated). Also supports inquiry mode to display allocation status.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSVEHIN (shared vehicle input)
- **MFS Output (MOD):** MFSVEHIN (shared vehicle output)
- **Message Format:** Input: function (AL=Allocate/IQ=Inquiry), VIN, dealer code, production ID, priority (HI/NR/LO). Output: VIN, production ID, year/make/model, dealer, priority, old/new status, build date, plant.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.PRODUCTION_ORDER | SELECT | Look up production order by VIN |
| AUTOSALE.PRODUCTION_ORDER | UPDATE | Set allocated dealer and allocation date |
| AUTOSALE.VEHICLE | SELECT | Get current vehicle status |
| AUTOSALE.VEHICLE | UPDATE | Set dealer code and status to 'AL' |
| AUTOSALE.DEALER | SELECT | Validate dealer exists and is active |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN validation and decoding |
| COMSTCK0 | Stock update (ALOC function) |
| COMLGEL0 | Audit log entry |

### Key Business Logic
- Two modes: AL (Allocate) and IQ (Inquiry).
- **Allocate:** VIN validated via COMVALD0. Dealer validated as active. Production order must have build status PR (Produced) or CM (Complete). Cannot allocate if already allocated to another dealer. Updates PRODUCTION_ORDER with allocated dealer and date. Updates VEHICLE with dealer code and status 'AL'. Calls COMSTCK0 with 'ALOC' function.
- **Inquiry:** Joins PRODUCTION_ORDER and VEHICLE to display allocation status.
- Priority levels: HI (High), NR (Normal), LO (Low).
- VIN decoded for manufacturer, model year, and assembly details.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLPRORD
- DCLVEHCL
- DCLVHSTH

### Error Handling
- IMS GU failure sets return code 16.
- VIN validation failure reported with COMVALD0 message.
- Dealer not found or inactive returns error.
- Production order not found returns error.
- Vehicle not ready (wrong build status) returns error with current status.
- Already allocated returns warning with existing dealer.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/{vin}/allocate, GET /api/vehicles/{vin}/allocation
- **React Page:** VehicleSearch
- **Key Considerations:** Allocation is a critical supply chain operation. The production order integration may need to interface with manufacturer APIs. Priority-based allocation logic could be enhanced with rules engine. VIN decode should be a shared utility service.
