# REGSUB00 — Registration Submission to State

## Overview
- **Program ID:** REGSUB00
- **Module:** REG — Registration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** RGSB
- **Source:** cbl/online/reg/REGSUB00.cbl
- **Lines of Code:** 491
- **Complexity:** Medium

## Purpose
Submits a validated registration to the state DMV for processing. Verifies the registration is in 'VL' (Validated) status before proceeding. Generates a unique tracking number, updates status to 'SB' (Submitted), records the submission date, and inserts a status history record into TITLE_STATUS.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASRGSB00
- **Message Format:** Input: registration ID. Output: reg details (VIN, deal, customer, vehicle desc), registration state/type, submission date, tracking number.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.REGISTRATION | SELECT | Read and verify current status is 'VL' |
| AUTOSALE.REGISTRATION | UPDATE | Set status to 'SB', record submission date |
| AUTOSALE.VEHICLE | SELECT | Look up vehicle description |
| AUTOSALE.CUSTOMER | SELECT | Look up customer name |
| AUTOSALE.TITLE_STATUS | SELECT MAX | Get next status sequence |
| AUTOSALE.TITLE_STATUS | INSERT | Record submission status history |
| AUTOSALE.REG_TRACK_SEQ | NEXT VALUE | Generate tracking number sequence |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Registration ID is required.
- Registration must be in 'VL' (Validated) status to submit.
- Tracking number format: "RG" + state code + YYMMDD + 5-digit sequence (e.g., RGTX26032900001).
- Sequence generated from AUTOSALE.REG_TRACK_SEQ.
- Updates REGISTRATION with status 'SB' and SUBMISSION_DATE = CURRENT DATE.
- Inserts TITLE_STATUS record with status 'SB' and description 'SUBMITTED TO STATE DMV'.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- Registration not found returns "REGISTRATION NOT FOUND".
- Non-VL status returns "REGISTRATION MUST BE VALIDATED BEFORE SUBMIT".
- DB2 errors call COMDBEL0 with program/paragraph/table context.

## Modernization Notes
- **Target Module:** registration
- **Target Endpoint:** POST /api/registrations/{regId}/submit
- **React Page:** RegistrationTracker
- **Key Considerations:** Tracking number generation logic should be moved to a service. The VL->SB transition is a key workflow step. Consider async processing for actual DMV submission in the modernized system.
