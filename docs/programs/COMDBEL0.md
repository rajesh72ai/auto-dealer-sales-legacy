# COMDBEL0 — DB2 Error Handler

## Overview
- **Program ID:** COMDBEL0
- **Type:** Common Module
- **Source:** cbl/common/COMDBEL0.cbl
- **Lines of Code:** 551
- **Complexity:** Medium

## Purpose
Centralizes all DB2 SQLCODE evaluation, error message formatting, and recovery actions across the AUTOSALES system. Categorizes SQL errors by severity, provides retry recommendations for deadlock/timeout conditions, and issues IMS ROLL calls for fatal errors.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMDBEL0' USING LK-SQLCA-AREA LK-DBE-PROGRAM-NAME LK-DBE-SECTION-NAME LK-DBE-TABLE-NAME LK-DBE-OPERATION LK-DBE-RESULT-AREA`.

Return codes: 00 (OK), 04 (Not Found), 08 (Recoverable Error), 12 (Fatal).

### Database Access
None (receives SQLCA from caller).

### Called Subroutines
| Program | Purpose |
|---------|---------|
| CBLTDLI | IMS ROLL call for fatal errors (backs out transaction) |

### Key Business Logic
- **SQLCODE categorization:** Maps SQLCODEs to categories: Success (0), Not Found (+100), Duplicate Key (-803), Multiple Rows (-811), Constraint Violations (-530/-531/-532/-545), Resource Unavailable (-904), Deadlock (-911), Timeout (-913), Authorization (-551/-552), Plan Mismatch (-818), Data Exception (-302 to -305).
- **Severity levels:** O (OK), I (Info), W (Warning), E (Error), F (Fatal).
- **Retry flag:** Set to 'Y' for deadlock (-911) and timeout (-913).
- **Error messages:** Detailed formatted messages including program name, section, table, operation, SQLCODE, SQLSTATE, and SQLERRD(3).
- **IMS ROLL:** For fatal errors (RC=12), calls CBLTDLI to issue IMS ROLL (backs out all DB2 and DL/I changes). If ROLL fails (e.g., running in batch), appends "ROLL FAILED" to the error message.

### Copybooks Used
None (SQLCA passed via linkage).

### Input/Output
- **Input:** Standard SQLCA, program context fields
- **Output:** Result code, retry flag, formatted error message, SQLCODE display, SQLSTATE, category, severity, rows affected

## Modernization Notes
- **Target:** Exception handling middleware / DB error interceptor
- **Key considerations:** The SQLCODE-to-category mapping is DB2-specific. Modern databases have different error codes. The IMS ROLL call is IMS-specific; modern equivalent is transaction rollback. The retry recommendation for deadlock/timeout is a universal pattern.
- **Dependencies:** Called by batch programs (BATCRM00, BATDLAKE, BATDMS00, BATGLINT, BATINB00). Uses CBLTDLI for IMS ROLL.
