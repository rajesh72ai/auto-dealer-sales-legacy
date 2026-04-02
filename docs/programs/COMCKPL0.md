# COMCKPL0 — Checkpoint/Restart Handler

## Overview
- **Program ID:** COMCKPL0
- **Type:** Common Module
- **Source:** cbl/common/COMCKPL0.cbl
- **Lines of Code:** 570
- **Complexity:** High

## Purpose
Manages IMS checkpoint/restart for all batch programs. Issues CHKP and XRST calls to IMS DL/I and tracks restart control state in the DB2 RESTART_CONTROL table. Provides a unified interface for checkpoint initialization, issuance, restart recovery, and job completion/failure marking.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMCKPL0' USING LS-CHKP-FUNCTION LS-CHKP-DATA LS-CHKP-RESULT`.

Function codes:
- **INIT** - Initialize checkpoint, check for pending restart from prior abend
- **CHKP** - Issue IMS symbolic checkpoint
- **XRST** - Issue extended restart (restore checkpoint data)
- **DONE** - Mark job complete in RESTART_CONTROL
- **FAIL** - Mark job failed/abended in RESTART_CONTROL

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.RESTART_CONTROL | SELECT | Check for prior abended/in-progress runs |
| AUTOSALE.RESTART_CONTROL | INSERT | Create new run record on normal start |
| AUTOSALE.RESTART_CONTROL | UPDATE | Update checkpoint ID, records processed, status |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| CBLTDLI | IMS DL/I interface for CHKP and XRST calls |

### Key Business Logic
- **INIT:** Queries RESTART_CONTROL for status S/P/A (started/processing/abended). If abended run found, sets restart flag and returns checkpoint data. If no prior run, inserts a new row with status 'S'.
- **CHKP:** Increments checkpoint sequence, populates a 240-byte save area, calls CBLTDLI with CHKP function, and updates RESTART_CONTROL with current checkpoint ID, records processed, last key, and timestamp.
- **XRST:** Calls CBLTDLI with XRST function to restore the save area from the last checkpoint, then returns the restored data to the caller.
- **DONE:** Updates RESTART_CONTROL status to 'C' (Complete) with a completion timestamp.
- **FAIL:** Updates RESTART_CONTROL status to 'A' (Abended).
- **Checkpoint ID format:** First 4 chars of program name + 4-digit sequence number.

### Copybooks Used
- WSSQLCA
- DCLRSTCT (RESTART_CONTROL DCLGEN)

### Input/Output
- **Input:** Linkage section parameters from calling program
- **Output:** Return code, return message, restart flag, checkpoint ID, records processed, last key, IMS status

## Modernization Notes
- **Target:** Job orchestration / state management in the batch framework
- **Key considerations:** The IMS CHKP/XRST calls are IMS-specific and will not exist in a modern environment. The RESTART_CONTROL table pattern (tracking job state in DB2) is portable. Modern equivalents include Spring Batch job repository or cloud workflow state management.
- **Dependencies:** Called by all 11 batch programs. Depends on IMS DL/I (CBLTDLI) and DB2 RESTART_CONTROL table.
