# VEHINQ00 — Vehicle Inquiry by VIN or Stock Number

## Overview
- **Program ID:** VEHINQ00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHIQ
- **Source:** cbl/online/veh/VEHINQ00.cbl
- **Lines of Code:** 666
- **Complexity:** High

## Purpose
Searches by VIN (exact) or stock number. Displays full vehicle details, installed options, status history, and current location. Uses SQL JOIN to MODEL_MASTER for description. Sub-queries via cursors for VEHICLE_OPTION and VEHICLE_STATUS_HIST. Display only -- no updates.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT)
- **MFS Output (MOD):** (via WSMSGFMT)
- **Message Format:** Input: function (VN=VIN/ST=Stock), VIN or stock number. Output: VIN, stock number, status, year/make/model/name, colors, body style, trim, dealer, lot, odometer, receive date, days in stock, PDI flag, damage flag, up to 8 options, up to 6 status history entries.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Look up vehicle by VIN or stock number |
| AUTOSALE.MODEL_MASTER | JOIN | Get model name, body style, trim level |
| AUTOSALE.VEHICLE_OPTION | SELECT (cursor) | Fetch installed options (up to 8) |
| AUTOSALE.VEHICLE_STATUS_HIST | SELECT (cursor) | Fetch status history (up to 6, most recent first) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format VIN display (FVIN function) |
| COMVINL0 | VIN decode/lookup (DECO function) |

### Key Business Logic
- Two search modes: VN (by VIN, default) and ST (by stock number).
- Vehicle lookup joins MODEL_MASTER for model name, body style, and trim.
- Handles nullable columns (receive date, lot location, stock number, dealer code) with null indicators.
- Options cursor: fetches installed options (INSTALLED_FLAG='Y'), ordered by option code. Shows code, description, and price.
- History cursor: fetches status changes ordered by sequence DESC (most recent first). Shows sequence, from/to status, changed-by user, timestamp, and reason. Handles nullable change reason.
- VIN decoded via COMVINL0 for manufacturer details.
- VIN formatted for display via COMFMTL0.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLVEHCL
- DCLVHOPT
- DCLVHSTH
- DCLMODEL

### Error Handling
- IMS GU failure sets return code 16.
- Vehicle not found returns "VEHICLE NOT FOUND".
- DB2 error returns "DB2 ERROR ON VEHICLE LOOKUP".
- Cursor open failures silently skip options/history sections.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** GET /api/vehicles/{vin}, GET /api/vehicles?stockNumber=
- **React Page:** VehicleSearch
- **Key Considerations:** This is the most comprehensive vehicle display program. Options and history should be separate sub-resources or included via query parameter. The rich data model (colors, body style, trim, PDI, damage) maps well to a vehicle detail API response. VIN decode can be a separate microservice.
