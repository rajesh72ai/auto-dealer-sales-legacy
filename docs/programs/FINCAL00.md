# FINCAL00 — Loan Payment Calculator

## Overview
- **Program ID:** FINCAL00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNCL
- **Source:** cbl/online/fin/FINCAL00.cbl
- **Lines of Code:** 568
- **Complexity:** Medium

## Purpose
A pure calculation tool with no database updates. Calculates loan payments using COMLONL0, displays monthly payment, total of payments, total interest, a side-by-side comparison across 36/48/60/72-month terms, and a first-year (12-month) amortization schedule. Supports what-if scenarios by varying APR or term.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: principal (11), APR (6), term (3), down payment (11). Output: input echo, calculated payment, term comparison table, 12-month amortization table.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| (none) | - | Read-only calculator, no DB2 access |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLONL0 | Loan payment calculation (called 6 times: primary + 4 comparisons + amortization) |
| COMFMTL0 | Field formatting |

### Key Business Logic
- Net principal = principal - down payment; must be >= $500
- APR validated: 0-30%
- Default term: 60 months if not specified
- Primary calculation via COMLONL0 with CALC function
- Term comparison: iterates 36/48/60/72-month terms at same APR using WS-COMP-TERMS table (REDEFINES pattern)
- Amortization display: 12-month table showing month number, payment, principal portion, interest portion, cumulative interest, and remaining balance
- COMLONL0 returns a 12-entry amortization table (WS-LR-AMORT-TABLE) with each entry containing month, payment, principal, interest, cumulative interest, and balance

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 8=validation, 16=IMS error
- COMLONL0 return code checked; error message forwarded to output
- IMS ISRT failure sets abend code 'FNCL'

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** POST /api/finance/calculator/loan
- **React Page:** FinanceCalculator
- **Key Considerations:** This is a stateless calculator -- ideal for a pure function/service. BigDecimal required for all financial math. The comparison and amortization features map well to a rich JSON response. Consider caching or memoization since no DB state is involved. The COMLONL0 amortization algorithm (likely standard loan amortization formula: M = P[r(1+r)^n]/[(1+r)^n-1]) should be reimplemented with precise decimal arithmetic.
