# FINAPP00 — Finance Application Capture

## Overview
- **Program ID:** FINAPP00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNAP
- **Source:** cbl/online/fin/FINAPP00.cbl
- **Lines of Code:** 831
- **Complexity:** High

## Purpose
Captures a finance application for a sales deal, supporting three finance types: Loan (L), Lease (S), and Cash (C). For loans, it calculates the monthly payment via COMLONL0. It generates a unique finance ID via COMSEQL0, inserts a FINANCE_APP record with status NW (New), and updates the SALES_DEAL status to FI (In F&I).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: deal number (10), finance type (1), lender code (5), amount (11), APR (6), term (3), down payment (11). Output: finance ID, status, deal info, payment breakdown.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Validate deal exists with status AP |
| AUTOSALE.SALES_DEAL | UPDATE | Set deal status to FI (In F&I) |
| AUTOSALE.FINANCE_APP | INSERT | Create new finance application record |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLONL0 | Loan payment calculation (principal, APR, term) |
| COMSEQL0 | Generate unique finance ID sequence number |
| COMFMTL0 | Field formatting utility |
| COMLGEL0 | Audit logging (INSERT on FINANCE_APP, UPDATE on SALES_DEAL) |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- Supports three finance types: L=Loan (full calculation), S=Lease (deferred to FINLSE00), C=Cash (minimal, no financing)
- Loan APR validated between 0-30%, term between 12-84 months
- Non-cash types require a lender code
- Loan principal = amount requested minus down payment; calls COMLONL0 with CALC function
- Finance ID format: dealer code (5 chars) + formatted sequence number (7 chars) = 12 chars
- Deal must be in AP (Approved) status before entering F&I
- On success, deal status transitions from AP to FI
- Null indicators used extensively for optional fields (lender name, APR approved, stipulations, etc.)

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLSLDEL (SALES_DEAL DCLGEN)
- DCLFINAP (FINANCE_APP DCLGEN)

### Error Handling
- Return code pattern: 0=success, 4=warning, 8=validation error, 16=system/DB2 error
- DB2 errors delegated to COMDBEL0 with program name, section, table, and operation context
- IMS GU/ISRT failures set return code and message; ISRT failure sets abend code 'FNAP'
- All audit logging via COMLGEL0 with old/new value tracking

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** POST /api/finance/applications
- **React Page:** FinanceApplicationForm
- **Key Considerations:** Use BigDecimal for all financial amounts. Loan calculation logic lives in COMLONL0 and should become a shared service. Finance ID generation needs a modern sequence/UUID approach. The three finance types (loan/lease/cash) map naturally to a discriminated union or strategy pattern. Null indicator handling maps to nullable/optional fields in the API schema.
