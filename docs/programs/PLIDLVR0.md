# PLIDLVR0 — Delivery Confirmation

## Overview
- **Program ID:** PLIDLVR0
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLDL
- **Source:** cbl/online/pli/PLIDLVR0.cbl
- **Lines of Code:** 699
- **Complexity:** High

## Purpose
Dealer confirms receipt of a vehicle from shipment. Input includes VIN or shipment ID, damage inspection results, and odometer reading. Updates vehicle status to DL (Delivered), receive date, and odometer. If all vehicles in a shipment are delivered, updates shipment status to DL with actual arrival date. Triggers stock update via COMSTCK0 and schedules a PDI (Pre-Delivery Inspection).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: CF=confirm, SH=by shipment, IQ=inquiry), VIN (17), shipment ID (4), dealer code (5), odometer (6), damage flag (1), damage desc (80), inspection note (60). Output: VIN, dealer, shipment ID, status, recv date, odometer, damage info, shipment completion status, PDI scheduled date.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Verify vehicle exists, status SH or AL |
| AUTOSALE.VEHICLE | UPDATE | Set status=DL, receive date, odometer, damage info |
| AUTOSALE.SHIPMENT_VEHICLE | SELECT | Find shipment for VIN |
| AUTOSALE.SHIPMENT_VEHICLE | SELECT | Count delivered vs total vehicles |
| AUTOSALE.SHIPMENT | UPDATE | Set status=DL and actual arrival date when all delivered |
| AUTOSALE.PDI_SCHEDULE | INSERT | Schedule PDI for delivered vehicle |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock update (RECV function) |
| COMLGEL0 | Audit logging |
| COMVALD0 | VIN format validation |

### Key Business Logic
- **Single delivery (CF)**: validates VIN status is SH or AL, updates vehicle with delivery details, checks shipment completion, triggers stock update, schedules PDI
- **Bulk delivery (SH)**: updates all vehicles in a shipment to DL status with same date/odometer, updates shipment status to DL
- **Shipment completion check**: counts delivered vs total vehicles; when equal, marks shipment as DL with actual arrival date
- **PDI auto-scheduling**: generates PDI ID (MAX+1), inserts PDI_SCHEDULE with 42 checklist items, status=SC
- Damage flag and description captured with null indicator handling
- Date formatting from COBOL CURRENT-DATE intrinsic function

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 4=warning (PDI insert failed), 8=validation, 12=DB2 error, 16=IMS error
- PDI schedule failure is non-fatal (warning only)
- IMS ISRT failure sets abend code 'PLIDLVR0'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/{vin}/delivery, POST /api/shipments/{id}/delivery
- **React Page:** DeliveryConfirmation
- **Key Considerations:** This is a multi-step workflow (delivery + shipment completion + stock update + PDI scheduling) that should use a saga or choreography pattern. The damage inspection data could include photos in a modern system. The automatic PDI scheduling on delivery is a good candidate for an event-driven trigger. The 42-item checklist is hard-coded and should be configurable. Consider barcode/QR scanning for VIN input.
