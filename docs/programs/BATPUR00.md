# BATPUR00 — Purge/Archive Processing

## Overview
- **Program ID:** BATPUR00
- **Type:** Batch
- **Source:** cbl/batch/BATPUR00.cbl
- **Lines of Code:** 502
- **Complexity:** Medium

## Purpose
Quarterly data housekeeping batch that archives completed registrations older than 2 years, purges audit log entries older than 3 years, and purges expired recall notifications older than 1 year. Uses batched deletes (500 rows at a time) to avoid DB2 lock escalation.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Three-phase processing.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.REGISTRATION | SELECT/UPDATE | Archive old registrations (set status to 'ER') |
| AUTOSALE.AUDIT_LOG | DELETE | Purge entries older than 3 years |
| AUTOSALE.RECALL_NOTIFICATION | DELETE | Purge expired notifications older than 1 year |
| AUTOSALE.RESTART_CONTROL | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management (INIT/CHKP/DONE) |
| COMLGEL0 | Audit logging for archived registrations |

### Key Business Logic
- **Phase 1 - Archive Registrations:** Selects registrations with status 'IS' and issued date <= 2 years ago. Updates status to 'ER' (Expired/Archived).
- **Phase 2 - Purge Audit Log:** Deletes in batches of 500 rows where AUDIT_TS < 3 years ago. Loops until fewer than 500 rows are deleted, preventing lock escalation.
- **Phase 3 - Purge Notifications:** Deletes in batches of 500 from RECALL_NOTIFICATION where NOTIF_DATE < 1 year ago and RESPONSE_FLAG = 'N'.
- **Cutoff dates:** Registration = CURRENT DATE - 2 YEARS; Audit = CURRENT TIMESTAMP - 3 YEARS; Notifications = CURRENT DATE - 1 YEAR.
- **Checkpointing:** Every 1000 records.

### Copybooks Used
- WSCKPT00
- WSRSTCTL
- SQLCA

### Input/Output
- **Input:** DB2 tables only
- **Output:** DB2 updates/deletes, DISPLAY statements to SYSOUT

## Modernization Notes
- **Target:** Database maintenance / data lifecycle management service
- **Key considerations:** The batched delete pattern (FETCH FIRST 500 ROWS ONLY) is critical for avoiding lock escalation and should be preserved in any modern implementation. Retention periods are business rules.
- **Dependencies:** Depends on COMCKPL0, COMLGEL0. Operates independently on historical data.
