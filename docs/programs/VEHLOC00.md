# VEHLOC00 — Lot Location Management

## Overview
- **Program ID:** VEHLOC00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHLC
- **Source:** cbl/online/veh/VEHLOC00.cbl
- **Lines of Code:** 729
- **Complexity:** High

## Purpose
Manages lot locations for dealer vehicle storage. Supports four functions: inquiry (list locations), add new location, update location details, and assign vehicle to location. CRUD on LOT_LOCATION table. When assigning, updates VEHICLE.LOT_LOCATION and checks capacity.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT)
- **MFS Output (MOD):** (via WSMSGFMT)
- **Message Format:** Input: function (IQ/AD/UP/AS), dealer code, location code, description, type, max capacity, active flag, VIN. Output: location detail list (up to 10 rows with code, description, type, capacity, count, available, active), assignment confirmation.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.LOT_LOCATION | SELECT (cursor) | List locations for dealer |
| AUTOSALE.LOT_LOCATION | INSERT | Add new lot location |
| AUTOSALE.LOT_LOCATION | SELECT | Read existing for update |
| AUTOSALE.LOT_LOCATION | UPDATE | Update location details or count |
| AUTOSALE.VEHICLE | SELECT | Verify vehicle for assignment |
| AUTOSALE.VEHICLE | UPDATE | Set vehicle's lot location |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit log entry |
| COMDBEL0 | DB error handling |

### Key Business Logic
- Four functions: IQ (Inquiry), AD (Add), UP (Update), AS (Assign).
- **Inquiry:** Lists up to 10 locations with capacity, current count, available spots, and active flag.
- **Add:** Validates location type (L=Lot, S=Showroom, V=Service, O=Overflow), capacity > 0, and description required. Defaults active flag to 'Y'. Detects duplicate via SQLCODE -803.
- **Update:** Reads current record, applies only non-blank input fields, then updates. Supports partial updates.
- **Assign:** Verifies vehicle exists at this dealer. Checks location exists, is active, and has available capacity. Decrements old location count if vehicle had one. Updates vehicle's lot location. Increments new location count.
- Available calculated as MAX_CAPACITY - CURRENT_COUNT, minimum 0.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLLOTLC
- DCLVEHCL

### Error Handling
- Missing dealer code returns error.
- Location code required for non-inquiry functions.
- Invalid location type returns error with valid values.
- Duplicate location code returns specific error.
- Capacity full returns "LOT LOCATION IS AT FULL CAPACITY".
- Vehicle not at dealer returns error.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** GET /api/dealers/{code}/locations, POST /api/dealers/{code}/locations, PUT /api/dealers/{code}/locations/{loc}, POST /api/vehicles/{vin}/location
- **React Page:** VehicleSearch
- **Key Considerations:** The four-function pattern should become separate REST endpoints. Capacity management is important for lot optimization. The partial update pattern maps to PATCH semantics. Location assignment should be atomic with count updates.
