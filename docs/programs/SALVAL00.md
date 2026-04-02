# SALVAL00 — Deal Validation

## Overview
- **Program ID:** SALVAL00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALV
- **Source:** cbl/online/sal/SALVAL00.cbl
- **Lines of Code:** 716
- **Complexity:** High

## Purpose
Performs comprehensive validation of a deal before it can be submitted for manager approval. Checks multiple business rules across several tables: customer validity and credit status, vehicle availability, pricing within dealer guidelines (minimum margin), required deal components, tax calculation, trade-in payoff verification, and incentive eligibility. Returns a list of validation errors or "DEAL VALID" status, and updates deal status to PA (Pending Approval) if valid.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLVL00 (Validation Response)
- **Message Format:** Input is simply the deal number (10). Output shows deal header, overall result (DEAL VALID or VALIDATION FAILED), and up to 10 numbered validation error messages describing each issue found.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Read deal details for validation |
| AUTOSALE.SALES_DEAL | UPDATE | Set status to PA (Pending Approval) if valid |
| AUTOSALE.CUSTOMER | SELECT | Verify customer exists and is valid |
| AUTOSALE.CREDIT_CHECK | SELECT | Verify credit check exists and is not expired |
| AUTOSALE.VEHICLE | SELECT | Verify vehicle is still available (not sold/transferred) |
| AUTOSALE.SYSTEM_USER | SELECT | Verify salesperson is active |
| AUTOSALE.SYSTEM_CONFIG | SELECT | Read dealer minimum margin guidelines |
| AUTOSALE.TRADE_IN | SELECT | Verify trade-in payoff info if trade exists |
| AUTOSALE.INCENTIVE_APPLIED | SELECT | Check applied incentives |
| AUTOSALE.INCENTIVE_PROGRAM | SELECT | Verify incentive eligibility still valid |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDBEL0 | DB2 error handling |
| COMMSGL0 | Message builder for validation error messages |

### Key Business Logic
- **Validation checks performed (up to 10 errors):**
  1. Customer must exist in CUSTOMER table.
  2. Credit check must exist with non-expired status (from CREDIT_CHECK).
  3. Vehicle must still be in available status (not SD/TR/HD).
  4. Salesperson must be an active user in SYSTEM_USER.
  5. Pricing must meet minimum margin from SYSTEM_CONFIG.
  6. All required deal fields must be populated (total price, vehicle price, etc.).
  7. Tax must be calculated (total tax > 0 or explicitly zero).
  8. If trade-in exists, payoff information must be verified.
  9. All applied incentives must still be valid (active, within date range, units available).
  10. Deal status must be in a validatable state (WS, NE).
- **Minimum margin:** Read from SYSTEM_CONFIG as a configurable threshold. Front gross margin percentage must meet or exceed this minimum.
- **Error accumulation:** Errors are accumulated (up to 10) rather than failing on first error, giving the user a complete picture of all issues.
- **Status transition:** Only if WS-VAL-ERROR-COUNT = 0, deal status is updated from current to PA (Pending Approval).
- **Credit expiry check:** Credit check must have a non-null, non-expired expiry date (typically 30 days from check).
- **Vehicle status check:** Vehicle must not be in SD (Sold), TR (Transferred), or HD (Hold for other deal).

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLCRDCK — DCLGEN for CREDIT_CHECK table
- DCLSYSCF — DCLGEN for SYSTEM_CONFIG table

### Error Handling
Uses WS-RETURN-CODE and WS-VAL-ERROR-COUNT patterns. Each validation check independently adds to the error list without short-circuiting. DB errors for the validation queries are handled via COMDBEL0 but treated as validation failures (e.g., "unable to verify customer" rather than a system error). The message builder COMMSGL0 formats each error consistently.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** POST /api/deals/{dealNumber}/validate
- **React Page:** DealValidation
- **Key Considerations:** This program is essentially a business rules engine and is a prime candidate for a rules-based validation framework (Drools, custom rule engine, or a validation service). Each validation rule should be independently testable and configurable. The minimum margin threshold being stored in SYSTEM_CONFIG is a good pattern that should be preserved. The error accumulation pattern (show all errors, not just the first) is excellent UX and should be maintained. The cross-table validation represents a significant integration surface that should be well-tested. In a microservices architecture, some validations (credit check, vehicle availability) may need to call other services.
