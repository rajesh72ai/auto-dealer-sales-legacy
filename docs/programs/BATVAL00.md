# BATVAL00 — Data Validation/Integrity Batch

## Overview
- **Program ID:** BATVAL00
- **Type:** Batch
- **Source:** cbl/batch/BATVAL00.cbl
- **Lines of Code:** 865
- **Complexity:** High

## Purpose
Weekly data integrity validation batch that checks for orphaned records (deals without valid customers, vehicles without valid dealers), validates VIN checksums on all vehicles using the COMVINL0 decoder module, checks for duplicate customer records, and writes all exceptions to a formatted SYSPRINT report.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Four-phase validation with report output.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Find deals with no matching customer |
| AUTOSALE.CUSTOMER | SELECT | Check customer existence; find duplicates by name+DOB+dealer |
| AUTOSALE.VEHICLE | SELECT/UPDATE | Check dealer existence; validate VIN checksums; flag invalid VINs |
| AUTOSALE.DEALER | SELECT | Check dealer existence |
| AUTOSALE.RESTART_CONTROL | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management |
| COMVINL0 | VIN validation and decoding |

### Key Business Logic
- **Phase 1 - Orphaned Deals:** Uses NOT EXISTS subquery to find deals (not cancelled/unwound) where CUSTOMER_ID has no matching CUSTOMER row.
- **Phase 2 - Orphaned Vehicles:** Uses NOT EXISTS subquery to find vehicles where DEALER_CODE has no matching DEALER row.
- **Phase 3 - VIN Validation:** Iterates all vehicles, calls COMVINL0 with 'VALD' function for each VIN. Invalid VINs get DAMAGE_FLAG set to 'Y' with description 'VIN CHECKSUM FAILED'.
- **Phase 4 - Duplicate Customers:** Self-joins CUSTOMER table on LAST_NAME + FIRST_NAME + DATE_OF_BIRTH + DEALER_CODE with C1.CUSTOMER_ID < C2.CUSTOMER_ID to find potential duplicates.
- **Report:** Formatted 132-byte report with page headers, section headers, detail lines, and summary counts.
- **Checkpointing:** Every 500 records.

### Copybooks Used
- WSCKPT00
- WSRSTCTL
- SQLCA

### Input/Output
- **Input:** DB2 tables only
- **Output:** SYSPRINT DD - 132-byte formatted exception report

## Modernization Notes
- **Target:** Data quality service / scheduled integrity checks in each domain module
- **Key considerations:** The four validation checks map to separate data quality rules. The VIN validation should remain centralized. The duplicate detection logic (name+DOB+dealer match) is a deduplication rule that may need ML-based fuzzy matching in a modern system.
- **Dependencies:** Depends on COMCKPL0, COMVINL0. Report consumed by operations/data quality team.
