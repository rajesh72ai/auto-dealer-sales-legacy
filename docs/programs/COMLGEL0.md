# COMLGEL0 — Audit Logging Module

## Overview
- **Program ID:** COMLGEL0
- **Type:** Common Module
- **Source:** cbl/common/COMLGEL0.cbl
- **Lines of Code:** 366
- **Complexity:** Medium

## Purpose
Inserts audit trail records into the AUDIT_LOG DB2 table for all data changes across the AUTOSALES system. Designed to never cause the calling transaction to abend; all audit failures are trapped and returned as warnings.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMLGEL0' USING LK-AUD-USER-ID LK-AUD-PROGRAM-ID LK-AUD-ACTION-TYPE LK-AUD-TABLE-NAME LK-AUD-KEY-VALUE LK-AUD-OLD-VALUE LK-AUD-NEW-VALUE LK-AUD-RETURN-CODE LK-AUD-ERROR-MSG`.

Return codes: 00 (success), 04 (warning - audit write failed, non-fatal).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.AUDIT_LOG | INSERT | Write audit trail record |

### Called Subroutines
None.

### Key Business Logic
- **Validation:** User ID and program ID are required. Action type validated against 12 known values: INS, UPD, DEL, INQ, APR, REJ, PRT, LON, LOF, XFR, CAN, SUB.
- **NULL handling:** TABLE_NAME, KEY_VALUE, OLD_VALUE, NEW_VALUE use VARCHAR with null indicators. Blank values are set to NULL.
- **Retry logic:** Retries up to 3 times on deadlock (-911) or timeout (-913).
- **Non-fatal design:** NEVER abends the caller. All errors return RC=04 with a warning message.
- **Timestamp:** Uses CURRENT TIMESTAMP in the INSERT for AUDIT_TS.

### Copybooks Used
- WSSQLCA
- DCLAUDIT (AUDIT_LOG DCLGEN)

### Input/Output
- **Input:** User ID, program ID, action type, table name, key value, old value (200 chars), new value (200 chars)
- **Output:** Return code, error message

## Modernization Notes
- **Target:** Event sourcing / audit trail service / centralized logging
- **Key considerations:** The non-fatal design pattern is critical and must be preserved. The retry-on-deadlock pattern is reusable. Modern equivalent might use async event publishing to avoid blocking the caller entirely.
- **Dependencies:** Called by most programs for audit trail. AUDIT_LOG table is the central audit store.
