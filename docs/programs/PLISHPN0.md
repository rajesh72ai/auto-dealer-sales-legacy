# PLISHPN0 — Shipment Creation

## Overview
- **Program ID:** PLISHPN0
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLSH
- **Source:** cbl/online/pli/PLISHPN0.cbl
- **Lines of Code:** 804
- **Complexity:** High

## Purpose
Groups allocated vehicles into transport loads. Creates a shipment record with auto-generated ID, validates vehicle status=AL, inserts into SHIPMENT_VEHICLE, calculates vehicle count, and estimates arrival date based on transport mode. Supports creating shipments, adding vehicles, dispatching, and inquiry.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: CR=create, AV=add vehicle, DP=dispatch, IQ=inquiry), shipment ID (4), carrier (6), origin plant (5), dest dealer (5), transport mode (2: TK/RL/OC/AR), VIN (17), departure date (10). Output: shipment details, route, dates, vehicle count, status, added VIN.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SHIPMENT | INSERT | Create new shipment |
| AUTOSALE.SHIPMENT | SELECT | Verify shipment exists, get status |
| AUTOSALE.SHIPMENT | UPDATE | Update vehicle count, set status=DP on dispatch |
| AUTOSALE.SHIPMENT_VEHICLE | INSERT | Add vehicle to shipment |
| AUTOSALE.SHIPMENT_VEHICLE | SELECT (cursor) | Iterate vehicles for dispatch |
| AUTOSALE.VEHICLE | SELECT | Verify vehicle status=AL |
| AUTOSALE.VEHICLE | UPDATE | Set status=SH on dispatch |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSEQL0 | Generate shipment ID sequence |
| COMSTCK0 | Stock update (SHIP function) per vehicle on dispatch |
| COMLGEL0 | Audit logging |

### Key Business Logic
- **Create (CR)**: validates carrier/origin/dest, generates shipment ID via COMSEQL0, estimates arrival based on mode:
  - TK (Truck): 3 days
  - RL (Rail): 7 days
  - OC (Ocean): 21 days
  - AR (Air): 1 day
  - Default: 5 days
- **Add Vehicle (AV)**: verifies shipment status=CR, vehicle status=AL, inserts SHIPMENT_VEHICLE with sequence number, increments vehicle count
- **Dispatch (DP)**: verifies status=CR and vehicles > 0, iterates all vehicles via cursor updating each to SH status, calls COMSTCK0 SHIP for each, sets shipment status=DP with departure date
- **Inquiry (IQ)**: retrieves shipment details by ID
- Vehicle sequence maintained via incremented counter (not DB sequence)

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 8=validation, 12=DB2 error, 16=IMS error
- Dispatch cursor properly opened/closed; RC=1 used as end-of-cursor signal
- IMS ISRT failure sets abend code 'PLISHPN0'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/shipments (create), POST /api/shipments/{id}/vehicles (add), POST /api/shipments/{id}/dispatch, GET /api/shipments/{id}
- **React Page:** ShipmentManagement
- **Key Considerations:** The create-add-dispatch workflow is a natural state machine (CR -> add vehicles -> DP). Transit time estimates should be configurable per route, not just per mode. The dispatch operation updates multiple vehicles and should be transactional. Consider integration with carrier booking APIs. The COMSTCK0 stock update per vehicle should be batched for performance. Shipment ID generation should use a modern approach.
