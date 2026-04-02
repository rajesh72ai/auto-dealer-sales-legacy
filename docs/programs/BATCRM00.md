# BATCRM00 — CRM Feed Extract

## Overview
- **Program ID:** BATCRM00
- **Type:** Batch
- **Source:** cbl/batch/BATCRM00.cbl
- **Lines of Code:** 557
- **Complexity:** Medium

## Purpose
Extracts new and changed customer records (based on LAST_UPDATED > last run date) along with their purchase history summaries and contact preferences. Writes a pipe-delimited output file for ingestion by an external CRM system and updates the CRM_SYNC_DATE on each extracted customer.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP (Batch Message Processing) program via JCL. Uses STOP RUN to terminate.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | SELECT | Read changed customers since last run |
| AUTOSALE.CUSTOMER | UPDATE | Set CRM_SYNC_DATE after extraction |
| AUTOSALE.SALES_DEAL | SELECT | Aggregate purchase history (count, total spent, last deal) |
| AUTOSALE.BATCH_CONTROL | SELECT | Get last run date |
| AUTOSALE.BATCH_CONTROL | UPDATE/INSERT | Update last run date and records processed |
| AUTOSALE.BATCH_CHECKPOINT | READ/UPDATE | Checkpoint/restart support via COMCKPL0 |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management |
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Logging utility |

### Key Business Logic
- **Initialization:** Reads last run date from BATCH_CONTROL; defaults to 1900-01-01 if no prior run exists. Checks for restart via COMCKPL0.
- **Customer cursor:** Selects all customers where LAST_UPDATED > last run date, ordered by CUSTOMER_ID.
- **Purchase history:** For each customer, aggregates COUNT(*), MAX(DEAL_DATE), SUM(TOTAL_PRICE) from SALES_DEAL for delivered/closed deals. Also fetches the most recent deal type.
- **Output format:** Writes a header row then pipe-delimited detail rows with customer demographics + purchase summary + extract date.
- **Sync update:** Updates CRM_SYNC_DATE on CUSTOMER for each extracted record.
- **Checkpointing:** Every 500 customers, issues a DB2 COMMIT and calls COMCKPL0.
- **Control table:** After processing, updates BATCH_CONTROL with today's date and record count.

### Copybooks Used
- WSCKPT00 (checkpoint working storage area)
- SQLCA (DB2 SQL Communication Area)

### Input/Output
- **Input:** AUTOSALE.CUSTOMER table (changed records)
- **Output:** CRMFILE DD — pipe-delimited sequential file with header + detail records (variable length, up to 800 bytes)

## Modernization Notes
- **Target:** CRM Integration microservice or event-driven CDC (Change Data Capture) pipeline
- **Key considerations:** The polling approach (last run date) should be replaced with CDC or event streaming. The pipe-delimited format maps directly to CSV export or API payload.
- **Dependencies:** Depends on COMCKPL0, COMDBEL0, COMLGEL0. Downstream CRM system consumes the extract file.
