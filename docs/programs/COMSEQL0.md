# COMSEQL0 — Sequence Number Generator

## Overview
- **Program ID:** COMSEQL0
- **Type:** Common Module
- **Source:** cbl/common/COMSEQL0.cbl
- **Lines of Code:** 378
- **Complexity:** Medium

## Purpose
Generates unique formatted sequence numbers for deals, registrations, finance applications, transfers, and shipments. Uses DB2 SELECT FOR UPDATE to serialize concurrent access to the SYSTEM_CONFIG table where sequence counters are stored.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMSEQL0' USING LS-SEQ-REQUEST LS-SEQ-RESULT`.

Sequence types: DEAL, REG, FIN, TRAN, SHIP.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SYSTEM_CONFIG | SELECT FOR UPDATE | Read current sequence value with row lock |
| AUTOSALE.SYSTEM_CONFIG | UPDATE | Increment and store new sequence value |

### Called Subroutines
None.

### Key Business Logic
- **Type mapping:** DEAL -> NEXT_DEAL_NUM (prefix D-), REG -> NEXT_REG_NUM (prefix R-), FIN -> NEXT_FIN_NUM (prefix F-), TRAN -> NEXT_TRAN_NUM (prefix T-), SHIP -> NEXT_SHIP_NUM (prefix S-).
- **Concurrency:** SELECT FOR UPDATE locks the row during the read-modify-write cycle to prevent duplicate numbers.
- **Increment:** Reads current value from CONFIG_VALUE, converts via FUNCTION NUMVAL, adds 1, updates.
- **Overflow:** Maximum sequence is 99999. Returns RC=12 on overflow.
- **Formatted output:** Prefix + 5-digit zero-padded number (e.g., D-00123).
- **Retry logic:** Retries up to 3 times on deadlock (-911) or timeout (-913).
- **Audit:** Updates UPDATED_BY and UPDATED_TS on each increment.

### Copybooks Used
- WSSQLCA
- DCLSYSCF (SYSTEM_CONFIG DCLGEN)

### Input/Output
- **Input:** Sequence type, dealer code, user ID
- **Output:** Raw number, formatted number (7 chars), return code, message, SQLCODE

## Modernization Notes
- **Target:** Database sequence or distributed ID generator (Snowflake IDs, UUID, etc.)
- **Key considerations:** The DB2 SELECT FOR UPDATE pattern is a serialization bottleneck. Modern databases support native sequences (CREATE SEQUENCE) which are much more efficient. The 99999 limit is very low for a production system.
- **Dependencies:** Used by deal creation, registration, finance application, transfer, and shipment modules. SYSTEM_CONFIG table stores counters.
