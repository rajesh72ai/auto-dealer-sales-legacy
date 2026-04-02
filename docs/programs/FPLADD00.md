# FPLADD00 — Floor Plan Vehicle Add

## Overview
- **Program ID:** FPLADD00
- **Module:** FPL
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FPLA
- **Source:** cbl/online/fpl/FPLADD00.cbl
- **Lines of Code:** 561
- **Complexity:** Medium

## Purpose
Notifies a lender of a new vehicle added to the floor plan. Looks up invoice price from the vehicle table and dealer/lender information. Inserts a FLOOR_PLAN_VEHICLE record with invoice price as balance, floor date as current date, and calculates the curtailment date based on lender-specific curtailment days. Status set to AC (Active).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Direct MFS message (not WSMSGFMT)
- **MFS Output (MOD):** ASFPLA00
- **Message Format:** Input: VIN (17), lender ID (5), dealer code (5). Output: title, VIN, vehicle description, invoice price, lender name, floor/curtailment dates, status, floor plan ID, dealer name, message.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Get invoice price, status, dealer code |
| AUTOSALE.DEALER | SELECT | Get dealer name |
| AUTOSALE.LENDER | SELECT | Get lender name and curtailment days |
| AUTOSALE.FLOOR_PLAN_VEHICLE | INSERT | Create new floor plan record |
| SYSIBM.SYSDUMMY1 | SELECT | Generate floor plan ID via AUTOSALE.FPL_SEQ |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN format validation |
| COMFMTL0 | Currency formatting for invoice price |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- Vehicle must be in AV (Available) or IT (In-Transit) status to be floor-planned
- Floor plan ID generated via DB2 sequence AUTOSALE.FPL_SEQ
- Invoice amount from vehicle record becomes both INVOICE_AMOUNT and initial CURRENT_BALANCE
- Curtailment date = current date + lender's CURTAILMENT_DAYS (calculated via DB2 date arithmetic)
- Interest accrued initialized to zero
- Status set to AC (Active)
- Vehicle description formatted as: model year + make + model (STRING concatenation)

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Error flow uses WS-OUT-MESSAGE as error flag (checked for SPACES before proceeding)
- DB2 errors delegated to COMDBEL0
- IMS status checked after GU and ISRT calls

## Modernization Notes
- **Target Module:** vehicle (floor plan sub-module)
- **Target Endpoint:** POST /api/floor-plan/vehicles
- **React Page:** FloorPlanAddVehicle
- **Key Considerations:** Floor plan ID generation should use a modern sequence or UUID. Curtailment date calculation is a simple date-add operation. The lender-specific curtailment days should be configurable. Consider webhook integration for lender notification instead of the implicit notification pattern. BigDecimal for invoice and balance amounts.
