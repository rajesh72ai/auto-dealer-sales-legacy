# COMSTCK0 — Stock Count Update Module

## Overview
- **Program ID:** COMSTCK0
- **Type:** Common Module
- **Source:** cbl/common/COMSTCK0.cbl
- **Lines of Code:** 532
- **Complexity:** High

## Purpose
Updates stock position counts and vehicle status for all inventory movements (receive, sell, hold, release, transfer in/out, allocate). Enforces valid status transitions, updates both STOCK_POSITION counts and VEHICLE status, and inserts a VEHICLE_STATUS_HIST record for audit trail.

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMSTCK0' USING LS-STK-REQUEST LS-STK-RESULT`.

Function codes: RECV, SOLD, HOLD, RLSE, TRNI, TRNO, ALOC.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Look up current vehicle status by VIN |
| AUTOSALE.VEHICLE | UPDATE | Set new vehicle status |
| AUTOSALE.STOCK_POSITION | SELECT FOR UPDATE | Read current stock counts with lock |
| AUTOSALE.STOCK_POSITION | UPDATE | Apply count changes |
| AUTOSALE.VEHICLE_STATUS_HIST | SELECT | Get next sequence number for history |
| AUTOSALE.VEHICLE_STATUS_HIST | INSERT | Insert status change audit record |

### Called Subroutines
None.

### Key Business Logic
- **Status transitions:** RECV -> AV; SOLD -> SD (from AV or AL only); HOLD -> HD (from AV only); RLSE -> AV (from HD only); TRNI -> AV (from IT expected); TRNO -> IT (from AV only); ALOC -> AL (from AV only).
- **Stock count adjustments:** RECV: +1 on-hand; SOLD: -1 on-hand, +1 sold-MTD/YTD; HOLD: -1 on-hand, +1 on-hold; RLSE: +1 on-hand, -1 on-hold; TRNI: +1 on-hand, -1 in-transit; TRNO: -1 on-hand; ALOC: +1 allocated.
- **Negative prevention:** On-hand, in-transit, and on-hold counts are clamped to 0 minimum.
- **Status history:** Each change inserts a row with VIN, sequence number, old/new status, changed-by user, optional reason, and timestamp.
- **Validation:** Function code, dealer code, and VIN are all required. Invalid status transitions return RC=8.

### Copybooks Used
- WSSQLCA
- DCLSTKPS (STOCK_POSITION DCLGEN)
- DCLVHSTH (VEHICLE_STATUS_HIST DCLGEN)
- DCLVEHCL (VEHICLE DCLGEN)

### Input/Output
- **Input:** Function code, dealer code, VIN, user ID, reason (optional)
- **Output:** Old/new status, updated stock counts (on-hand, in-transit, allocated, on-hold, sold-MTD, sold-YTD), return code, SQLCODE

## Modernization Notes
- **Target:** Inventory Management service with event-driven stock updates
- **Key considerations:** The status transition validation is a state machine that should be preserved exactly. The stock count adjustment logic is straightforward but critical for inventory accuracy. The SELECT FOR UPDATE serialization may need an optimistic locking alternative. The status history is an event-sourcing pattern.
- **Dependencies:** Called by deal processing, vehicle receiving, transfers, and allocation modules. Central to inventory management.
