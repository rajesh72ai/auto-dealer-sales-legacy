# FINAPV00 — Finance Approval/Decline Processing

## Overview
- **Program ID:** FINAPV00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNAV
- **Source:** cbl/online/fin/FINAPV00.cbl
- **Lines of Code:** 711
- **Complexity:** High

## Purpose
Processes finance application decisions: Approve (AP), Conditional (CD), or Decline (DN). On approval, it recalculates the monthly payment using the approved APR and amount via COMLONL0, then updates both the FINANCE_APP and SALES_DEAL tables. Tracks lender decisions with timestamps and supports stipulations for conditional approvals.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: finance ID (12), action (2: AP/CD/DN), approved amount (11), approved APR (6), stipulations (200). Output: requested vs approved terms, monthly payment, total payments, total interest, stipulations, new status.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FINANCE_APP | SELECT | Retrieve existing application details |
| AUTOSALE.FINANCE_APP | UPDATE | Set status (AP/CD/DN), amounts, timestamps |
| AUTOSALE.SALES_DEAL | UPDATE | Set AMOUNT_FINANCED on approval |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLONL0 | Recalculate loan payment with approved terms |
| COMFMTL0 | Field formatting |
| COMLGEL0 | Audit logging for status changes |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- Three decision paths via EVALUATE: Approve recalculates payment, Conditional records stipulations, Decline allows resubmit
- Approval requires both approved amount and APR; conditional requires stipulations text
- For loan type (finance_type='L'), recalculation: principal = approved amount - down payment, then COMLONL0 CALC
- Cannot re-decide an already-approved application (status='AP')
- Old status saved for audit trail before update
- On approve: updates SALES_DEAL.AMOUNT_FINANCED with approved amount
- Displays side-by-side: requested terms vs approved terms with recalculated payment schedule

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLFINAP (FINANCE_APP DCLGEN)
- DCLSLDEL (SALES_DEAL DCLGEN)

### Error Handling
- Return code pattern: 0=success, 8=validation, 16=system error
- DB2 errors routed through COMDBEL0 with section/table/operation context
- IMS ISRT failure sets abend code 'FNAV'
- Audit log captures old status and new status for every decision

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** PUT /api/finance/applications/{financeId}/decision
- **React Page:** FinanceApprovalScreen
- **Key Considerations:** BigDecimal for all financial recalculations. The approve/conditional/decline workflow maps to a state machine. Stipulations field (VARCHAR 200) needs proper text handling. The recalculation-on-approve pattern should be an atomic transaction covering both FINANCE_APP and SALES_DEAL updates.
