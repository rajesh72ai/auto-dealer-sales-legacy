# REGSTS00 — Registration Status Update

## Overview
- **Program ID:** REGSTS00
- **Module:** REG — Registration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** RGST
- **Source:** cbl/online/reg/REGSTS00.cbl
- **Lines of Code:** 620
- **Complexity:** High

## Purpose
Updates a registration record with state DMV response. Handles approval (status 'IS' with plate and title number), rejection (status 'RJ' with reason), processing (status 'PG'), and error (status 'ER'). Validates current status allows update (must be SB or PG). Inserts audit trail into TITLE_STATUS table and logs via COMLGEL0.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASRGST00
- **Message Format:** Input: registration ID, new status (PG/IS/RJ/ER), plate number, title number, reject reason. Output: old/new status, plate, title, issued date, reject reason.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.REGISTRATION | SELECT | Read current registration status |
| AUTOSALE.REGISTRATION | UPDATE | Apply new status, plate, title, issued date |
| AUTOSALE.TITLE_STATUS | SELECT MAX | Get next status sequence number |
| AUTOSALE.TITLE_STATUS | INSERT | Record status history entry |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Registration ID and new status are required.
- Valid new status codes: PG (Processing), IS (Issued), RJ (Rejected), ER (Error).
- For IS (Issued): plate number and title number are required; updates PLATE_NUMBER, TITLE_NUMBER, and ISSUED_DATE.
- For RJ (Rejected): rejection reason is required.
- Status transition rules: current status must be SB (Submitted) or PG (Processing). Cannot transition from PG to PG.
- Valid transitions: SB->PG, SB->IS, SB->RJ, SB->ER, PG->IS, PG->RJ, PG->ER.
- Each status change inserts a TITLE_STATUS history record with sequence number, status code, and description.
- Separate SQL UPDATE statements for each new status (IS, RJ, PG, ER) to handle status-specific column updates.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- SQLCODE +100 on registration lookup returns "REGISTRATION NOT FOUND".
- DB2 errors on update or insert call COMDBEL0.
- Invalid status transition returns descriptive error message.

## Modernization Notes
- **Target Module:** registration
- **Target Endpoint:** PUT /api/registrations/{regId}/status
- **React Page:** RegistrationTracker
- **Key Considerations:** Status transition validation logic should be extracted into a state machine service. The separate UPDATE statements per status can be consolidated. TITLE_STATUS inserts become event-sourced status changes in the new architecture.
