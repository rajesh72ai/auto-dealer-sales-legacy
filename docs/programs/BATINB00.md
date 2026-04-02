# BATINB00 — Inbound Data Feed Processing

## Overview
- **Program ID:** BATINB00
- **Type:** Batch
- **Source:** cbl/batch/BATINB00.cbl
- **Lines of Code:** 614
- **Complexity:** Medium

## Purpose
Processes inbound vehicle allocation feeds from the manufacturer. Reads fixed-length allocation records, validates each record (type, VIN, make, model year, dealer, invoice amount), inserts new vehicles into AUTOSALE.VEHICLE, and automatically adds new model codes to MODEL_MASTER. Rejected records are written to a reject file with reason codes.

## Technical Details

### Entry Point / Call Interface
Invoked as an IMS BMP program via JCL. Reads from INFILE DD, rejects to REJFILE DD.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT/INSERT | Check for duplicate VIN, insert new vehicle |
| AUTOSALE.MODEL_MASTER | SELECT/INSERT | Check if model exists, insert new models |
| AUTOSALE.BATCH_CHECKPOINT | READ/UPDATE | Checkpoint/restart |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMCKPL0 | Checkpoint/restart management |
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Logging utility |

### Key Business Logic
- **Record types:** VH (Vehicle) and AL (Allocation) are valid record types.
- **Validation rules:** Record type must be VH or AL; VIN must not be blank; make must not be blank; model year must be 2000-2030; dealer code required; invoice amount must be > 0.
- **Duplicate check:** COUNT(*) on VEHICLE table by VIN before insert. Duplicates are rejected with reason 'DUP-VIN'.
- **Vehicle insert:** Sets initial status to 'AV' (Available). Includes all vehicle attributes from the inbound record.
- **Model master maintenance:** After successful vehicle insert, checks if MODEL_MASTER has the model code + year combination. If not, inserts a new model record with base pricing from the allocation.
- **Reject handling:** Writes original record + 10-byte reason code to REJFILE.
- **Checkpointing:** Every 500 records.

### Copybooks Used
- WSCKPT00
- SQLCA

### Input/Output
- **Input:** INFILE DD - Fixed 400-byte allocation records from manufacturer
- **Output:** REJFILE DD - Fixed 410-byte reject records (400 data + 10 reason)

## Modernization Notes
- **Target:** Vehicle Allocation ingest API / message consumer in Inventory module
- **Key considerations:** The validation rules are straightforward and map to API input validation. The MODEL_MASTER auto-creation is a side effect that should become its own service. Reject file pattern maps to a dead-letter queue.
- **Dependencies:** Depends on COMCKPL0, COMDBEL0, COMLGEL0. Upstream: manufacturer allocation system.
