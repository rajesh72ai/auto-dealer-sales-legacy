# COMTAXL0 — Tax Calculation Module

## Overview
- **Program ID:** COMTAXL0
- **Type:** Common Module
- **Source:** cbl/common/COMTAXL0.cbl
- **Lines of Code:** 525
- **Complexity:** High

## Purpose
Looks up state, county, and city tax rates from the TAX_RATE DB2 table and calculates all tax components for a vehicle sale, including sales tax at each jurisdiction level, doc fees (capped per state law), title fees, and registration fees.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMTAXL0' USING LK-TAX-STATE-CODE LK-TAX-COUNTY-CODE LK-TAX-CITY-CODE LK-TAX-INPUT-AREA LK-TAX-RESULT-AREA LK-TAX-RETURN-CODE LK-TAX-ERROR-MSG`.

Return codes: 00 (success), 04 (rate not found), 08 (invalid input), 12 (DB2 error).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.TAX_RATE | SELECT | Look up tax rates by state/county/city with effective date |

### Called Subroutines
None.

### Key Business Logic
- **Tax rate lookup:** Three-level fallback: (1) state+county+city, (2) state+county+default city ('00000'), (3) state+default county+default city. Uses effective date logic.
- **Net taxable amount:** Selling price - trade allowance (cannot be negative). Most states allow trade-in tax credit.
- **Tax calculation:** State tax = net taxable * state rate; County tax = net taxable * county rate; City tax = net taxable * city rate. Each rounded to nearest cent. Total = sum of all three.
- **Doc fee:** Capped at state maximum (from DOC_FEE_MAX in TAX_RATE). If requested fee exceeds cap, uses cap.
- **Title fee:** Flat fee from TAX_RATE table.
- **Registration fee:** From TAX_RATE table (same for new and used currently).
- **Grand total:** Total tax + total fees (doc + title + registration).
- **Validation:** State code required, taxable amount must be > 0, trade allowance >= 0, vehicle type must be NW/US/DM.
- **Sale date:** If provided, used for effective-date lookup; otherwise uses current date.

### Copybooks Used
- WSSQLCA
- DCLTAXRT (TAX_RATE DCLGEN)

### Input/Output
- **Input:** State/county/city codes, taxable amount, trade allowance, doc fee request, vehicle type, sale date
- **Output:** State/county/city rates and amounts, total tax, net taxable, doc/title/reg fees, total fees, grand total

## Modernization Notes
- **Target:** Tax calculation service (or integration with external tax provider like Avalara)
- **Key considerations:** Multi-jurisdiction tax calculation with effective dates is complex. The three-level fallback is important. Doc fee caps vary by state and are a compliance requirement. An external tax service would handle rate maintenance automatically.
- **Dependencies:** Called by COMPRCL0 (pricing engine) and deal processing. TAX_RATE table must be maintained with current rates.
