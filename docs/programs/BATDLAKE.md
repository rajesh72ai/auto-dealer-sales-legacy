# BATDLAKE — Data Lake Extract

## Overview
- **Program ID:** BATDLAKE
- **Type:** Batch
- **Source:** cbl/batch/BATDLAKE.cbl
- **Lines of Code:** 682
- **Complexity:** High

## Purpose
Reads today's entries from the AUDIT_LOG table to identify which records changed across the system. For each changed record, extracts the full current row from the corresponding source table and writes a JSON-like delimited output for data lake ingestion.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Uses STOP RUN to terminate.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.AUDIT_LOG | SELECT | Read today's change entries |
| AUTOSALE.SALES_DEAL | SELECT | Extract full deal record for changed deals |
| AUTOSALE.VEHICLE | SELECT | Extract full vehicle record for changed vehicles |
| AUTOSALE.CUSTOMER | SELECT | Extract full customer record for changed customers |
| AUTOSALE.FINANCE_APP | SELECT | Extract full finance app record |
| AUTOSALE.REGISTRATION | SELECT | Extract full registration record |
| AUTOSALE.BATCH_CHECKPOINT | READ/UPDATE | Checkpoint/restart support |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management |
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Logging utility |

### Key Business Logic
- **Audit-driven extraction:** Reads AUDIT_LOG for today's date, iterates each entry to determine which table was modified.
- **Table dispatch:** Uses EVALUATE on TABLE_NAME to route to the appropriate extract paragraph (SALES_DEAL, VEHICLE, CUSTOMER, FINANCE_APP, REGISTRATION).
- **JSON-like output:** Each extracted record is formatted as a pseudo-JSON string with table name, key fields, action type, and timestamp.
- **Checkpointing:** Every 1000 records, issues COMMIT and calls COMCKPL0.
- **Error handling:** DB2 errors on individual record extractions increment error count but do not stop processing.

### Copybooks Used
- WSCKPT00
- SQLCA

### Input/Output
- **Input:** AUTOSALE.AUDIT_LOG (today's changes)
- **Output:** OUTFILE DD — JSON-like delimited extract (variable length, up to 2000 bytes)

## Modernization Notes
- **Target:** Real-time CDC pipeline (Debezium/Kafka Connect) or cloud data lake ETL
- **Key considerations:** The audit-log-driven approach is a form of CDC. Modern replacement would use database log-based CDC for lower latency. The JSON-like format maps naturally to actual JSON events.
- **Dependencies:** Depends on COMCKPL0, COMDBEL0, COMLGEL0. All five core tables are read.
