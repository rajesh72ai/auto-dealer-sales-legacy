# PLIRECON — Production-to-Stock Reconciliation

## Overview
- **Program ID:** PLIRECON
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLRC
- **Source:** cbl/online/pli/PLIRECON.cbl
- **Lines of Code:** 641
- **Complexity:** High

## Purpose
Compares PRODUCTION_ORDER vs VEHICLE tables to find discrepancies. Identifies: produced but not in vehicle table, allocated but not shipped (>14 days), shipped but not delivered (>21 days), and status mismatches. Shows exception list with reason codes and a summary of total produced, allocated, shipped, delivered, and exceptions. Display only -- no updates.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: SM=summary, EX=exceptions, FL=full), plant code (5), model year (4), make (3), date from (10), date to (10). Output: filter echo, summary counts (produced/allocated/shipped/delivered/exceptions), up to 10 exception detail rows.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.PRODUCTION_ORDER | SELECT (COUNT) | Total produced count |
| AUTOSALE.VEHICLE | SELECT (COUNT) | Allocated, shipped, delivered counts |
| AUTOSALE.PRODUCTION_ORDER + VEHICLE | LEFT JOIN (COUNT) | Exception count |
| AUTOSALE.PRODUCTION_ORDER + VEHICLE | LEFT JOIN (cursor) | Exception details |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDTEL0 | Date calculations (days since build) |
| COMFMTL0 | Formatting utility |
| COMMSGL0 | Message builder for formatted output |

### Key Business Logic
- **Exception reason codes**:
  - NV: Produced but no vehicle record (LEFT JOIN NULL)
  - NS: Allocated > 14 days but not shipped
  - ND: Shipped > 21 days but not delivered
  - SM: Status mismatch between PRODUCTION_ORDER and VEHICLE
- **Summary counts**: 5 separate COUNT queries with optional filters (plant, year, make)
- **Cursor for exceptions**: complex LEFT JOIN with CASE expression to compute reason code, filtering out 'OK' results
- **Filters**: plant code, model year, make code -- all optional ("OR parameter = default" pattern)
- Each exception row shows: VIN, prod status, vehicle status, reason code, reason description, days since build, plant
- Days since build calculated via COMDTEL0

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 8=validation, 12=DB2 error, 16=IMS error
- Cursor errors caught and EOF flagged
- IMS ISRT failure sets abend code 'PLIRECON'

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** GET /api/vehicles/reconciliation?plant={code}&year={year}&make={make}
- **React Page:** ProductionReconciliationReport
- **Key Considerations:** This is a complex reporting query that should use SQL views or stored procedures rather than cursor-based iteration. The exception detection logic (CASE expression with date arithmetic) is valuable business logic to preserve. The 14-day and 21-day thresholds should be configurable. Consider running this as a scheduled job that generates alerts. The 10-row exception limit is artificial -- modern UI should support full pagination. This maps well to a data quality dashboard with drill-down.
