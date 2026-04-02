# ADMTAX00 — Tax Rate Maintenance

## Overview
- **Program ID:** ADMTAX00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMT
- **Source:** cbl/online/adm/ADMTAX00.cbl
- **Lines of Code:** 808
- **Complexity:** High

## Purpose
Maintains the TAX_RATE table for state, county, and city tax rates along with associated fees (doc fee max, title fee, registration fee). Validates rates between 0 and 15%, verifies combined rate does not exceed 20%, and performs a test tax calculation on a $30,000 sample price using the COMTAXL0 module. Supports inquiry, add, and update with effective date logic.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADTAX (Tax Rate Maintenance Screen)
- **MFS Output (MOD):** ASTAXI00 (Tax Rate Inquiry Response)
- **Message Format:** Input includes function (INQ/ADD/UPD), state code (2), county code (5), city code (5), state/county/city rates (8 each as decimal), doc fee max, title fee, reg fee, effective/expiry dates, user ID. Output shows rates as both decimal and percentage, combined rate, all fees, effective dates, and a test calculation showing tax on a $30,000 sale.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.TAX_RATE | SELECT | Inquiry by state/county/city with current effective date logic |
| AUTOSALE.TAX_RATE | INSERT | Add new tax rate record |
| AUTOSALE.TAX_RATE | UPDATE | Update existing tax rate by state/county/city/effective_date |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMTAXL0 | Test tax calculation on $30,000 sample price — returns itemized tax breakdown |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Rate validation:** Each rate (state, county, city) must be between 0 and 0.15 (15%). Validated individually.
- **Combined rate check:** Sum of state + county + city rates must not exceed 0.2000 (20%).
- **Effective date logic:** Inquiry selects where effective_date <= CURRENT DATE and expiry_date is null or >= CURRENT DATE, ordered by effective_date desc, first row only.
- **Test calculation:** On inquiry, calls COMTAXL0 with the state/county/city codes and a $30,000 test price. If the tax module returns RC=0, uses its result; otherwise falls back to manual calculation (price * combined rate). Displays test price, calculated tax, and total.
- **Tax module result:** COMTAXL0 returns itemized breakdown: state tax, county tax, city tax, doc fee, title fee, reg fee, total tax amount.
- **Nullable expiry:** Expiry date supports null (current rate with no expiry).
- **Fee handling:** Doc fee max, title fee, and reg fee default to 0 if not provided.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLTAXRT — DCLGEN for TAX_RATE table

### Error Handling
Standard SQLCODE pattern with COMDBEL0. Duplicate key (-803) caught on insert with "already exists for this date" message. COMTAXL0 failure is handled gracefully by falling back to manual rate calculation.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/tax-rates/{state}/{county}/{city}, POST /api/tax-rates, PUT /api/tax-rates/{state}/{county}/{city}/{effectiveDate}, GET /api/tax-rates/calculate?price={amount}&state={}&county={}&city={}
- **React Page:** TaxRateManagement
- **Key Considerations:** The tax rate effective date logic is a temporal data pattern that must be preserved. The test calculation feature should become a separate /calculate endpoint. Tax rate validation rules (max 15% individual, max 20% combined) are business rules that should be configurable. The COMTAXL0 integration represents a reusable tax calculation service that should become a shared microservice or utility class.
