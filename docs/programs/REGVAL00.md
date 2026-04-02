# REGVAL00 — Registration Validation

## Overview
- **Program ID:** REGVAL00
- **Module:** REG — Registration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** RGVL
- **Source:** cbl/online/reg/REGVAL00.cbl
- **Lines of Code:** 521
- **Complexity:** High

## Purpose
Validates a registration record against state rules. Checks VIN validity, customer data completeness, registration state existence in TAX_RATE, registration type validity, and fee calculation. If all validations pass, updates status to 'VL' (Validated). Returns failure messages if any checks fail, leaving status as 'PR' (Preparing).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASRGVL00
- **Message Format:** Input: registration ID. Output: reg details, validation pass/fail counts (up to 5 failure messages), status.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.REGISTRATION | SELECT | Read registration with lien holder, fees |
| AUTOSALE.REGISTRATION | UPDATE | Set status to 'VL' if all checks pass |
| AUTOSALE.CUSTOMER | SELECT | Read customer name/address for completeness check |
| AUTOSALE.TAX_RATE | SELECT COUNT | Verify registration state has active tax rate |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN format validation |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Registration ID is required. Registration must be in 'PR' (Preparing) status.
- Five validation checks performed:
  1. **VIN present and valid** (via COMVALD0 with 'VIN' function)
  2. **Customer data complete** (last name, address, city, zip all non-blank)
  3. **Registration state exists** in TAX_RATE with no expiry date
  4. **Registration type valid** (NW, TF, RN, or DP)
  5. **Fees calculated** (reg fee and title fee not both zero)
- Each check increments either valid-checks or fail-checks counter.
- Up to 5 failure messages returned in output array.
- If no failures, updates status to 'VL' and logs via COMLGEL0.
- If any failures, leaves status as 'PR' with failure details.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- Registration not found returns error.
- Non-PR status returns "REGISTRATION MUST BE IN PREPARING STATUS".
- DB2 errors call COMDBEL0.
- Validation failures are collected (not short-circuited) up to 5 messages.

## Modernization Notes
- **Target Module:** registration
- **Target Endpoint:** POST /api/registrations/{regId}/validate
- **React Page:** RegistrationTracker
- **Key Considerations:** Validation rules should be extracted into a validation service with structured error responses. The multi-check approach with collected errors maps well to a modern validation framework returning an array of validation errors.
