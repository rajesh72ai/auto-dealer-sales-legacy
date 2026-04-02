# FINCHK00 — Credit Check Interface

## Overview
- **Program ID:** FINCHK00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNCK
- **Source:** cbl/online/fin/FINCHK00.cbl
- **Lines of Code:** 793
- **Complexity:** High

## Purpose
Initiates a credit check for a customer or deal. First checks for an existing valid (non-expired) credit report to avoid duplicate bureau pulls. If none found, simulates a bureau response by generating a credit score based on customer income and debt. Inserts a CREDIT_CHECK record with score, tier (A-E), DTI ratio, and status=RC. Returns tier, score, recommended max finance amount, and monthly payment budget.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: DL=by deal, CU=by customer), deal number (10), customer ID (9). Output: customer name/SSN/DOB, credit score, tier, status, income, debt, DTI, max finance amount, monthly budget.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Resolve customer ID from deal number |
| AUTOSALE.CUSTOMER | SELECT | Fetch customer details (name, DOB, SSN, income) |
| AUTOSALE.CREDIT_CHECK | SELECT | Check for existing valid non-expired report |
| AUTOSALE.CREDIT_CHECK | INSERT | Create new simulated credit check record |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Field formatting |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- Two lookup modes: by deal (resolves customer via SALES_DEAL) or by direct customer ID
- Existing credit check reuse: queries for status='RC' and expiry >= current date, ordered by most recent
- **Simulated credit score formula** (income-based):
  - >= $100K income: score 780
  - >= $75K: score 720
  - >= $50K: score 650
  - >= $30K: score 580
  - < $30K: score 520
  - No income data: default 620
- **Credit tier assignment**: A >= 750, B >= 700, C >= 650, D >= 600, E < 600
- Monthly debt simulated at 20% of monthly income
- DTI ratio = (monthly debt / monthly income) * 100
- **Max finance recommendations by tier**: A=125% income, B=100%, C=75%, D=50%, E=25%
- **Monthly budget**: (monthly income * 15%) - existing debt; floor at $0
- Credit report expiry: current date + 30 days

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT
- DCLCRDCK (CREDIT_CHECK DCLGEN)
- DCLCUSTM (CUSTOMER DCLGEN)
- DCLSLDEL (SALES_DEAL DCLGEN)

### Error Handling
- Return code pattern: 0=success, 8=validation, 16=system error
- DB2 errors through COMDBEL0
- Extensive null indicator handling for nullable customer fields (DOB, SSN, income, employer)
- IMS ISRT failure sets abend code 'FNCK'

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** POST /api/finance/credit-check
- **React Page:** CreditCheckScreen
- **Key Considerations:** The simulated bureau logic should be replaced with a real credit bureau API integration (Experian/Equifax/TransUnion). The score-to-tier mapping and recommendation formulas are business rules that should be configurable. Credit report caching/reuse logic (30-day expiry) is a good pattern to keep. PII handling (SSN, DOB) requires encryption at rest and masking in responses.
