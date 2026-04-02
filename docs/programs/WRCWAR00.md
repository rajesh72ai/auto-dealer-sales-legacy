# WRCWAR00 — Warranty Registration

## Overview
- **Program ID:** WRCWAR00
- **Module:** WRC — Warranty & Recall
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** WRWA
- **Source:** cbl/online/wrc/WRCWAR00.cbl
- **Lines of Code:** 534
- **Complexity:** High

## Purpose
Creates warranty records for a sold vehicle. Generates four standard warranty coverages: Basic (3yr/36,000mi), Powertrain (5yr/60,000mi), Corrosion (5yr/unlimited), Emission (8yr/80,000mi). Start date = sale date. Calculates expiry dates via COMDTEL0. Inserts 4 WARRANTY records.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASWRWA00
- **Message Format:** Input: VIN, deal number. Output: VIN, deal number, sale date, warranty count, 4 warranty detail lines (type, start, expiry, mileage limit, deductible, status).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Look up deal, verify status, get sale date |
| AUTOSALE.WARRANTY | SELECT COUNT | Check if warranties already exist for deal |
| AUTOSALE.WARRANTY | INSERT (x4) | Insert 4 warranty coverage records |
| AUTOSALE.WARR_SEQ | NEXT VALUE | Generate warranty IDs |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDTEL0 | Date calculation - add years to sale date for expiry (ADD function) |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- VIN and deal number are required.
- Deal must be in DL (Delivered) or FI (F&I) status.
- VIN must match the deal's vehicle.
- Checks for existing warranties to prevent duplicates.
- Four standard warranty types with hard-coded parameters:
  1. **BASIC (BASC):** 3 years, 36,000 miles, $0 deductible
  2. **POWERTRAIN (PWRT):** 5 years, 60,000 miles, $100 deductible
  3. **CORROSION (CORR):** 5 years, 999,999 miles (unlimited), $0 deductible
  4. **EMISSION (EMIS):** 8 years, 80,000 miles, $0 deductible
- Expiry date calculated by adding warranty years to sale date via COMDTEL0.
- Each warranty assigned a unique ID from AUTOSALE.WARR_SEQ sequence.
- All warranties created with status 'AC' (Active).
- Loop exits immediately on any error (date calc or DB2 insert).
- All 4 warranties logged as a single audit entry.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Missing VIN or deal number returns error.
- Deal not found returns error.
- Deal not delivered/F&I returns error.
- VIN mismatch with deal returns error.
- Existing warranties returns "ALREADY REGISTERED".
- Date calculation error stops processing.
- DB2 insert error calls COMDBEL0 and stops remaining inserts.
- Warranty ID generation failure stops processing.

## Modernization Notes
- **Target Module:** registration (warranty)
- **Target Endpoint:** POST /api/vehicles/{vin}/warranty
- **React Page:** RegistrationTracker
- **Key Considerations:** Warranty terms (years, mileage, deductible) are currently hard-coded and should be configurable per make/model/year. The four standard types should be data-driven. Extended warranty purchases would need additional handling. This operation should be triggered automatically as part of the deal delivery workflow.
