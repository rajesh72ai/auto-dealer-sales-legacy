# COMLONL0 — Loan Calculation Module

## Overview
- **Program ID:** COMLONL0
- **Type:** Common Module
- **Source:** cbl/common/COMLONL0.cbl
- **Lines of Code:** 416
- **Complexity:** High

## Purpose
Calculates auto loan payments using the standard amortization formula. Provides monthly payment, total interest, total of payments, and the first 12-month amortization schedule. Handles 0% APR as a special case (simple division).

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMLONL0' USING LS-LOAN-REQUEST LS-LOAN-RESULT`.

Function codes: CALC (calculate + amortization), VALD (validate only), AMRT (calculate + amortization).

### Database Access
None.

### Called Subroutines
None.

### Key Business Logic
- **Amortization formula:** M = P * [r(1+r)^n] / [(1+r)^n - 1], where P = principal, r = monthly rate (APR/12/100), n = months.
- **0% APR special case:** Monthly payment = Principal / Term (simple division).
- **Power factor:** Computed iteratively (multiply (1+r) for each month) for precision rather than using a power function.
- **Amortization table:** First 12 months (or term if < 12). Each row: month number, payment, principal portion, interest portion, cumulative interest, remaining balance. Last payment adjusted for rounding. Negative balance prevented.
- **Validation:** Principal $500 - $999,999.99; APR 0% - 30%; Term 6-84 months.

### Copybooks Used
None.

### Input/Output
- **Input:** Principal, APR, term months, dealer code, VIN
- **Output:** Monthly payment, total payments, total interest, monthly rate, amortization months, 12-row amortization table (month, payment, principal, interest, cumulative interest, balance)

## Modernization Notes
- **Target:** Finance/Loan calculation service in the F&I module
- **Key considerations:** The iterative power factor calculation avoids floating-point precision issues and should be tested carefully when migrating to a language with native floating-point. The amortization table is commonly needed for Truth-in-Lending disclosures.
- **Dependencies:** Used by deal processing for loan quotes. No external dependencies.
