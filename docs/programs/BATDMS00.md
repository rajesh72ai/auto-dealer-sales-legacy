# BATDMS00 — DMS Interface Extract

## Overview
- **Program ID:** BATDMS00
- **Type:** Batch
- **Source:** cbl/batch/BATDMS00.cbl
- **Lines of Code:** 746
- **Complexity:** High

## Purpose
Sends deal and inventory data to an external Dealer Management System (DMS). Reads active inventory and recent deals for each active dealer, formats output per the DMS specification with file header, dealer header, inventory detail (IV), deal detail (SD), and file trailer records.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Uses STOP RUN to terminate.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.DEALER | SELECT | Iterate active dealers |
| AUTOSALE.VEHICLE | SELECT | Read active inventory per dealer (status AV/HD/TR) |
| AUTOSALE.SALES_DEAL | SELECT | Read deals since last sync per dealer |
| AUTOSALE.CUSTOMER | SELECT | Join for customer name on deal records |
| AUTOSALE.BATCH_CONTROL | SELECT/UPDATE/INSERT | Track last sync date |
| AUTOSALE.BATCH_CHECKPOINT | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management |
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Logging utility |

### Key Business Logic
- **Dealer-driven processing:** Iterates each active dealer, writing a dealer header record, then all inventory and deal records for that dealer.
- **File structure:** FH (file header) -> DH (dealer header) -> IV (inventory details) -> SD (deal details) -> FT (file trailer). Fixed 500-byte records.
- **Inventory detail:** Includes VIN, make, model, year, trim, colors, status, days-in-stock, invoice price, MSRP. Days-in-stock calculated via DB2 DAYS function.
- **Deal detail:** Includes deal number, customer name (joined from CUSTOMER), VIN, type, status, total price, tax, dates.
- **Control table:** Reads last sync date for delta extraction; updates after completion.
- **Checkpointing:** Every 500 records.

### Copybooks Used
- WSCKPT00
- SQLCA

### Input/Output
- **Input:** DB2 tables
- **Output:** DMSFILE DD - Fixed-format 500-byte sequential file with record type codes

## Modernization Notes
- **Target:** DMS Integration API or event-based sync service
- **Key considerations:** The fixed-format file structure with record types is a classic mainframe integration pattern. Modern replacement would use REST APIs or message queues with JSON payloads. The dealer-by-dealer nested loop pattern maps to a per-dealer API endpoint.
- **Dependencies:** Depends on COMCKPL0, COMDBEL0, COMLGEL0. External DMS system consumes the output file.
