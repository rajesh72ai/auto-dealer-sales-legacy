# BATRSTRT — Batch Restart Utility

## Overview
- **Program ID:** BATRSTRT
- **Type:** Batch
- **Source:** cbl/batch/BATRSTRT.cbl
- **Lines of Code:** 450
- **Complexity:** Low

## Purpose
Operations utility for batch abend recovery. Reads control cards from SYSIN to display, reset, or mark complete the checkpoint records for batch programs. Used by operations staff to manage batch job restarts after failures.

## Technical Details

### Entry Point / Call Interface
Invoked via JCL with SYSIN DD control cards. Writes report to SYSPRINT DD.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.BATCH_CHECKPOINT | SELECT | Display checkpoint status |
| AUTOSALE.BATCH_CHECKPOINT | DELETE | Reset checkpoint for re-run |
| AUTOSALE.BATCH_CHECKPOINT | UPDATE | Mark checkpoint as complete |

### Called Subroutines
None.

### Key Business Logic
- **Control card format:** Col 1-8: Program ID, Col 10-14: Action (DISP/RESET/COMPL).
- **DISP action:** Reads latest checkpoint for the program and displays: program ID, status, sequence, timestamp, last key, records in/out/error.
- **RESET action:** First displays current checkpoint, then DELETEs all checkpoint rows for the program. This allows a clean re-run from the beginning.
- **COMPL action:** Updates checkpoint status to 'CP' (Complete), which causes restart logic to skip restart on next run.
- **Report:** Writes formatted report to SYSPRINT with headers, detail lines, and action results.

### Copybooks Used
- SQLCA

### Input/Output
- **Input:** SYSIN DD - 80-byte control cards
- **Output:** SYSPRINT DD - 132-byte formatted report

## Modernization Notes
- **Target:** Operations dashboard / admin CLI tool
- **Key considerations:** This is a pure operations utility. Modern equivalent would be a web-based admin UI or CLI command for managing job state. The checkpoint/restart pattern itself may not be needed with cloud-native retry mechanisms.
- **Dependencies:** Operates on BATCH_CHECKPOINT table used by all batch programs via COMCKPL0.
