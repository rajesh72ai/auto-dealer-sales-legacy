# COMLESL0 — Lease Calculation Module

## Overview
- **Program ID:** COMLESL0
- **Type:** Common Module
- **Source:** cbl/common/COMLESL0.cbl
- **Lines of Code:** 451
- **Complexity:** High

## Purpose
Calculates complete lease payment structures including monthly depreciation, finance charge, tax, total payment, drive-off amount, and total cost summary. Implements the standard auto lease formula using money factor, residual value, and capitalized cost.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMLESL0' USING LS-LEASE-REQUEST LS-LEASE-RESULT`.

Function codes: CALC (full calculation), VALD (validate inputs only), ESTM (estimate without totals/drive-off).

### Database Access
None.

### Called Subroutines
None.

### Key Business Logic
- **Lease formula:** Residual = Cap Cost * Residual% / 100; Adj Cap = Cap Cost + Acq Fee - Down Payment; Depreciation = Adj Cap - Residual; Monthly Depr = Depreciation / Term; Monthly Finance = (Adj Cap + Residual) * Money Factor; Monthly Tax = (Monthly Depr + Monthly Finance) * Tax Rate / 100; Monthly Total = Monthly Depr + Monthly Finance + Monthly Tax.
- **Approximate APR:** Money Factor * 2400.
- **Drive-off:** First month + security deposit + acquisition fee + cap reduction.
- **Total cost:** All payments + cap reduction + acquisition fee.
- **Validation:** Cap cost >= $1,000; Cap reduction >= 0 and < cap cost; Money factor > 0 and <= 0.00500; Term must be 24, 36, 39, or 48 months; Residual 20-75%; Tax rate 0-15%.

### Copybooks Used
None.

### Input/Output
- **Input:** Cap cost, cap reduction, residual %, money factor, term months, tax rate, acquisition fee, security deposit, dealer code, VIN
- **Output:** All monthly components, residual amount, adjusted/net cap cost, depreciation, total payments, total interest, total tax, drive-off amount, approx APR, finance charge, total cost

## Modernization Notes
- **Target:** Finance/Lease calculation service in the F&I module
- **Key considerations:** The lease formula is standard industry practice. The money-factor-to-APR conversion (x2400) is an approximation. The strict term validation (24/36/39/48 only) may need to be configurable. All calculations use ROUNDED for precision.
- **Dependencies:** Used by deal processing for lease quotes. No external dependencies.
