# FINLSE00 — Lease Payment Calculator

## Overview
- **Program ID:** FINLSE00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNLS
- **Source:** cbl/online/fin/FINLSE00.cbl
- **Lines of Code:** 649
- **Complexity:** High

## Purpose
Full lease payment calculator using COMLESL0. Accepts capitalized cost, cap cost reduction, residual percentage, money factor, term, tax rate, acquisition fee, and security deposit. Displays adjusted cap cost, residual amount, monthly depreciation, monthly finance charge, monthly tax, total monthly payment, drive-off amount, and total of payments. If a deal number is provided, creates a LEASE_TERMS record in DB2.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: deal number (10), cap cost (11), cap reduction (11), residual % (6), money factor (8), term (3), tax rate (6), acquisition fee (8), security deposit (8). Output: input echo, lease payment breakdown, drive-off amount, totals.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FINANCE_APP | SELECT | Resolve finance ID for deal (type='S', most recent) |
| AUTOSALE.LEASE_TERMS | INSERT | Save lease terms if deal number provided |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLESL0 | Lease calculation engine |
| COMFMTL0 | Field formatting |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- **Lease calculation inputs**: cap cost, cap reduction, residual %, money factor, term, tax rate, acquisition fee, security deposit
- **Defaults**: residual 55%, money factor 0.00125, term 36 months, tax rate 7%, acquisition fee $695
- **COMLESL0 returns**: residual amount, adjusted cap cost, net cap cost, depreciation, monthly depreciation, monthly finance charge, monthly tax, total monthly payment, total payments, total interest equivalent, drive-off amount, approximate APR, finance charge, total cost
- Approximate APR derived from money factor (money factor * 2400)
- Drive-off = first month payment + acquisition fee + security deposit
- If deal number provided: looks up most recent lease finance app, then inserts LEASE_TERMS record with all calculated fields plus defaults (12000 miles/year, $0.25/excess mile, $395 disposition fee)
- Lease terms insert is non-fatal; failure logged but calculator still returns results

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT
- DCLLSTRM (LEASE_TERMS DCLGEN)
- DCLFINAP (FINANCE_APP DCLGEN)

### Error Handling
- Return code pattern: 0=success, 8=validation, 16=system error
- COMLESL0 error message forwarded to output
- Lease terms insert failure is non-fatal (shows warning message)
- IMS ISRT failure sets abend code 'FNLS'

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** POST /api/finance/calculator/lease
- **React Page:** LeaseCalculator
- **Key Considerations:** BigDecimal essential for money factor precision (6 decimal places). The lease calculation formula (depreciation + finance charge + tax) should be a shared service. Default values (residual %, money factor, miles/year) should be configurable. The conditional save-to-deal pattern maps well to a separate "save" action in the UI. Money factor to APR conversion (MF * 2400) is industry-standard.
