# PLITRNS0 — Transit Status Update

## Overview
- **Program ID:** PLITRNS0
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLTR
- **Source:** cbl/online/pli/PLITRNS0.cbl
- **Lines of Code:** 661
- **Complexity:** High

## Purpose
Receives carrier status updates, including EDI 214 feeds. Supports online entry or EDI batch processing. Looks up shipment and vehicle, validates status sequence, inserts TRANSIT_STATUS record with location and status. Updates shipment status. When status=DL (Delivered), triggers delivery confirmation by updating vehicle and shipment arrival date.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: OL=online, ED=EDI feed, IQ=inquiry), shipment ID (4), VIN (17), status code (2), location code (10), location desc (40), status date (10), status time (8), carrier ref (20), notes (60), EDI raw data (256). Output: shipment/VIN, old/new status, description, location, date/time, carrier ref, notes, sequence number.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SHIPMENT | SELECT | Verify shipment exists, get current status |
| AUTOSALE.SHIPMENT | UPDATE | Update shipment status, actual arrival date |
| AUTOSALE.TRANSIT_STATUS | SELECT | Get max sequence and last status |
| AUTOSALE.TRANSIT_STATUS | INSERT | New transit status event |
| AUTOSALE.VEHICLE | UPDATE | Set status=DL on delivery |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMEDIL0 | EDI 214 format parser (extracts shipment, VIN, status, location, dates) |
| COMDBEL0 | DB2 error handler |
| COMLGEL0 | Audit logging |

### Key Business Logic
- **Status codes**: DP=Departed, AR=Arrived, TF=Transferred, DL=Delivered, DY=Delayed
- **EDI 214 parsing**: raw EDI data passed to COMEDIL0 with '214' function; parsed fields mapped to standard input fields, then validated
- **Sequence validation**: gets MAX(STATUS_SEQ)+1 for new sequence; checks last status -- rejects if already DL
- **Status transition**: inserts TRANSIT_STATUS record, updates SHIPMENT.SHIPMENT_STATUS
- **Delivery handling**: when status=DL, updates VEHICLE.VEHICLE_STATUS to DL and SHIPMENT.ACT_ARRIVAL_DATE
- **Inquiry mode**: retrieves latest transit status for a shipment (ORDER BY STATUS_SEQ DESC, FETCH FIRST 1)
- Date/time default to current if not provided
- Transit status record includes: shipment ID, sequence, VIN, status code, description, location, date/time, carrier reference, notes, timestamp

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 8=validation, 12=DB2 error, 16=IMS error
- EDI parse errors surface the COMEDIL0 error message
- DB2 errors delegated to COMDBEL0
- IMS ISRT failure sets abend code 'PLITRNS0'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/shipments/{id}/transit-status, POST /api/shipments/edi-214
- **React Page:** TransitStatusUpdate
- **Key Considerations:** The EDI 214 integration is a critical modernization concern -- replace with carrier API webhooks or a modern EDI translation service (e.g., Stedi, Cleo). The status transition validation should use a state machine pattern. The delivery-triggered vehicle status update should be an event (e.g., "ShipmentDelivered" event). Consider real-time push notifications for transit updates. The TRANSIT_STATUS table is essentially an event log -- consider event sourcing pattern.
