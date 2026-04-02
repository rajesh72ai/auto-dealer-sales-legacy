# WRCINQ00 — Warranty Coverage Inquiry

## Overview
- **Program ID:** WRCINQ00
- **Module:** WRC — Warranty & Recall
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** WRCI
- **Source:** cbl/online/wrc/WRCINQ00.cbl
- **Lines of Code:** 484
- **Complexity:** Medium

## Purpose
Displays warranty coverage for a vehicle. Shows vehicle info (joined with MODEL_MASTER), current owner (from latest delivered SALES_DEAL), and all warranty coverages with type, start date, expiry date, mileage limit, deductible, active/expired status, and remaining days of coverage.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASWRCI00
- **Message Format:** Input: VIN. Output: vehicle description, color, sale date, owner name/phone, up to 6 warranty detail lines (type, start, expiry, mileage limit, deductible, status, remaining days).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Get vehicle details |
| AUTOSALE.MODEL_MASTER | JOIN | Get model name |
| AUTOSALE.SALES_DEAL | SELECT | Find latest delivered deal for owner |
| AUTOSALE.CUSTOMER | JOIN | Get owner name and phone |
| AUTOSALE.WARRANTY | SELECT (cursor) | Fetch all warranty coverages for VIN |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Currency formatting for deductible |
| COMDTEL0 | Date calculation (referenced but days calc done via SQL) |

### Key Business Logic
- VIN is required.
- Vehicle lookup joins MODEL_MASTER for full description.
- Owner determined from latest SALES_DEAL with status 'DL' (Delivered), using FETCH FIRST 1 ROW ONLY ordered by SALE_DATE DESC.
- Owner info displayed as "FirstName LastName" with phone.
- Warranty cursor fetches all warranty records ordered by expiry date.
- Warranty type descriptions looked up from table: BASC=BASIC, PWRT=POWERTRAIN, CORR=CORROSION, EMIS=EMISSION.
- Deductible displayed as "NONE" if zero, otherwise formatted as currency.
- Remaining days calculated via SQL: DAYS(EXPIRY_DATE) - DAYS(CURRENT DATE).
- Active/Expired determined by warranty status = 'AC' AND remaining days > 0.
- Up to 6 warranty records displayed.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- VIN required.
- Vehicle not found returns error.
- Owner not found displays "OWNER UNKNOWN" but doesn't fail.
- "NO WARRANTY RECORDS FOUND" if no warranties exist.
- DB2 cursor errors produce error messages.

## Modernization Notes
- **Target Module:** registration (warranty)
- **Target Endpoint:** GET /api/vehicles/{vin}/warranty
- **React Page:** RegistrationTracker
- **Key Considerations:** Remaining days calculation can be done in SQL or application layer. Owner lookup via latest deal is a common pattern that should be a shared service. Warranty type descriptions should be data-driven. Active/expired logic should consider mileage as well as date.
