# CUSCRED0 — Credit Pre-Qualification

## Overview
- **Program ID:** CUSCRED0
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSCR
- **Source:** cbl/online/cus/CUSCRED0.cbl
- **Lines of Code:** 749
- **Complexity:** High

## Purpose
Performs credit pre-qualification for customers. Fetches customer income data, checks for existing valid credit reports, and simulates a credit bureau call. For demonstration purposes, auto-generates a credit score based on income bracket and calculates debt-to-income (DTI) ratio. Returns credit tier, score, maximum financing amount, and expiry date. Reuses existing valid credit checks if found.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input via WSMSGFMT
- **MFS Output (MOD):** Credit Pre-Qualification screen
- **Message Format:** Input includes function (CK=check, VW=view), customer ID (9), monthly debt amount (9), bureau code (2). Output displays customer name/ID, annual and monthly income, credit tier with description, credit score, bureau code, DTI ratio with monthly debt, maximum recommended finance amount, expiry date, status code and description. Notes if existing valid credit check was reused.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | SELECT | Fetch customer income and name |
| AUTOSALE.CREDIT_CHECK | SELECT | Check for existing valid (non-expired) credit check |
| AUTOSALE.CREDIT_CHECK | INSERT | Create new credit check with status RQ (requested) |
| AUTOSALE.CREDIT_CHECK | UPDATE | Update with score, tier, DTI, and set expiry (+30 days) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format currency values |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Credit tier calculation (simulated):** Based on annual income brackets:
  - Tier A (Excellent): income > $100,000, score ~750-850
  - Tier B (Good): income > $75,000, score ~700-749
  - Tier C (Fair): income > $50,000, score ~650-699
  - Tier D (Below Average): income > $35,000, score ~600-649
  - Tier E (Poor): income <= $35,000, score ~500-599
- **DTI ratio:** Calculated as (monthly debt / monthly income) * 100 if monthly debt info available.
- **Max financing:** Calculated based on income and credit tier — higher tier allows larger financing relative to income.
- **Existing check reuse:** Before running a new check, queries for existing credit check with non-expired status. If found and still valid, reuses it instead of creating a new one.
- **Credit check lifecycle:** INSERT with status RQ (Requested), then UPDATE with results and set expiry = CURRENT DATE + 30 DAYS.
- **Bureau code:** Defaults to 'EQ' (Equifax) if not specified. Supports EQ, TU, EX.

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- WSAUDIT — Audit logging fields
- DCLCUSTM — DCLGEN for CUSTOMER table
- DCLCRDCK — DCLGEN for CREDIT_CHECK table

### Error Handling
Uses WS-RETURN-CODE pattern. DB errors via COMDBEL0. Validates customer exists before proceeding. Handles case where customer has no income on file.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** POST /api/customers/{id}/credit-check, GET /api/customers/{id}/credit-check
- **React Page:** CreditPreQualification
- **Key Considerations:** The simulated credit score calculation must be replaced with actual credit bureau API integration (Equifax, TransUnion, Experian). The income-based tier logic serves as a fallback/pre-screen. The existing check reuse pattern (30-day validity) is a cost-saving business rule that should be preserved. The DTI calculation is used downstream in deal validation and financing decisions. The credit check lifecycle (RQ -> completed) should map to an async pattern with webhook/polling in the modern system.
