# PLIVPDS0 — PDI Scheduling

## Overview
- **Program ID:** PLIVPDS0
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLPD
- **Source:** cbl/online/pli/PLIVPDS0.cbl
- **Lines of Code:** 781
- **Complexity:** High

## Purpose
Schedules Pre-Delivery Inspection (PDI) for received vehicles. Supports scheduling new inspections, starting (IP), completing (CM), failing (FL), and inquiry. On completion, updates VEHICLE.PDI_COMPLETE=Y, PDI_DATE, and sets vehicle status to AV (Available for sale). On failure, sets status=FL with notes and requires reschedule.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: SC=schedule, IP=start, CM=complete, FL=fail, IQ=inquiry), VIN (17), PDI ID (4), dealer code (5), scheduled date (10), technician ID (8), items passed (3), items failed (3), notes (200). Output: PDI ID, status, VIN, dealer, scheduled date, technician, checklist counts (total/passed/failed), notes, vehicle status, PDI complete flag.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Verify vehicle exists for scheduling |
| AUTOSALE.VEHICLE | UPDATE | Set PDI_COMPLETE=Y, PDI_DATE, status=AV on completion |
| AUTOSALE.PDI_SCHEDULE | SELECT | Generate PDI ID (MAX+1), lookup by ID or VIN |
| AUTOSALE.PDI_SCHEDULE | INSERT | Create new PDI schedule |
| AUTOSALE.PDI_SCHEDULE | UPDATE | Status transitions: SC->IP, IP->CM, IP->FL |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging for each status transition |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- **PDI lifecycle**: SC (Scheduled) -> IP (In Progress) -> CM (Completed) or FL (Failed)
- **Schedule (SC)**: creates PDI_SCHEDULE with 42 checklist items (hard-coded), status=SC, items passed/failed = 0
- **Start (IP)**: verifies current status=SC, updates to IP, optionally assigns technician
- **Complete (CM)**: verifies status=IP, records items passed/failed, sets COMPLETED_TS; updates VEHICLE: PDI_COMPLETE=Y, PDI_DATE=current, VEHICLE_STATUS=AV
- **Fail (FL)**: verifies status=IP, records items passed/failed with failure notes; vehicle remains in non-AV status
- **Inquiry (IQ)**: looks up by PDI ID or latest for VIN (ORDER BY PDI_ID DESC)
- **Lookup shared logic** (8500-LOOKUP-PDI): queries by PDI_ID or by VIN (latest), populates common output fields
- Technician ID uses null indicator handling (optional field)
- Notes field (200 chars) uses null indicator for INSERT/UPDATE

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 4=warning (vehicle update failed), 8=validation, 12=DB2 error, 16=IMS error
- Vehicle PDI flag update failure is non-fatal (warning)
- DB2 errors delegated to COMDBEL0
- Status transition violations produce descriptive error messages
- IMS ISRT failure sets abend code 'PLIVPDS0'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/{vin}/pdi (schedule), PUT /api/pdi/{id}/start, PUT /api/pdi/{id}/complete, PUT /api/pdi/{id}/fail, GET /api/pdi/{id}
- **React Page:** PDISchedulingDashboard
- **Key Considerations:** The PDI lifecycle (SC->IP->CM/FL) is a textbook state machine -- use a proper state machine library. The 42 checklist items should be configurable per dealer/make. Consider mobile-friendly UI for technicians doing inspections. The completion-triggers-availability workflow (PDI complete -> vehicle AV) should be event-driven. Photo/video capture for inspection items would be a valuable modern addition. Failure notes should support structured data (which items failed, required actions).
