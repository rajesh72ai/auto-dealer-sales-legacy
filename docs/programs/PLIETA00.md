# PLIETA00 — ETA Tracking Screen

## Overview
- **Program ID:** PLIETA00
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLET
- **Source:** cbl/online/pli/PLIETA00.cbl
- **Lines of Code:** 713
- **Complexity:** Medium

## Purpose
ETA tracking display. Search by VIN, dealer code, or shipment ID. Displays vehicle and shipment details with full transit history timeline, listing status, location, and timestamp for each transit event. Calculates days in transit and estimated days remaining. Display only -- no updates.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: VN=by VIN, DL=by dealer, SH=by shipment), VIN (17), dealer code (5), shipment ID (4). Output: shipment details (carrier, origin, dest, mode, dates), vehicle info, transit metrics, up to 10 transit history events.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Vehicle details (year, make, model) |
| AUTOSALE.SHIPMENT | SELECT | Shipment details (carrier, route, dates) |
| AUTOSALE.SHIPMENT_VEHICLE | JOIN | Link VIN to shipment |
| AUTOSALE.TRANSIT_STATUS | SELECT (cursor) | Transit history events ordered by timestamp |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDTEL0 | Date calculations (DAYS function for transit duration) |
| COMFMTL0 | Formatting utility |

### Key Business Logic
- Three search modes: by VIN (finds shipment via SHIPMENT_VEHICLE), by dealer (most recent non-delivered shipment), by shipment ID (direct lookup)
- Transit history: cursor on TRANSIT_STATUS ordered by STATUS_TS ASC, displays up to 10 events with sequence, status code, description, location, date, time, carrier reference
- **Days in transit**: COMDTEL0 DAYS function (current date - departure date)
- **Estimated remaining**: COMDTEL0 DAYS function (est arrival date - current date), floored at 0
- Null indicator handling for nullable actual arrival date and carrier reference
- If shipment is DL (delivered), remaining days shown as 0

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 4=warning (no transit events), 8=validation, 16=IMS error
- Transit history load failure is non-fatal (shows shipment info without events)
- IMS ISRT failure sets abend code 'PLIETA00'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** GET /api/shipments/track?vin={vin}&dealer={code}&shipmentId={id}
- **React Page:** ETATrackingDashboard
- **Key Considerations:** This is a read-only tracking screen -- perfect for a query-optimized view or materialized data. The transit history timeline is a natural fit for a visual timeline component in React. Consider real-time tracking updates via WebSocket or SSE. The three search modes map to query parameters on a single endpoint. Integration with carrier tracking APIs could provide live GPS data.
