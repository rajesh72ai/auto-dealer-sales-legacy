# FPLPAY00 — Floor Plan Payoff

## Overview
- **Program ID:** FPLPAY00
- **Module:** FPL
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FPLP
- **Source:** cbl/online/fpl/FPLPAY00.cbl
- **Lines of Code:** 403
- **Complexity:** Medium

## Purpose
Processes floor plan payoff when a vehicle is sold or transferred. Calculates final interest up to the payoff date using COMINTL0. Updates FLOOR_PLAN_VEHICLE: sets status to PD (Paid), records payoff date, zeroes balance, and updates cumulative interest.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Direct MFS message
- **MFS Output (MOD):** ASFPLP00
- **Message Format:** Input: VIN (17). Output: title, VIN, floor date, payoff date, original balance, final interest, total payoff, lender ID, status, days on floor, message.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.FLOOR_PLAN_VEHICLE | SELECT | Retrieve active floor plan by VIN |
| AUTOSALE.FLOOR_PLAN_VEHICLE | UPDATE | Set status=PD, payoff date, zero balance, final interest |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMINTL0 | Calculate total interest from floor date to payoff date |
| COMFMTL0 | Currency formatting for balance, interest, payoff amounts |
| COMLGEL0 | Audit logging |

### Key Business Logic
- Finds active (status='AC') floor plan for VIN
- Days on floor calculated via DB2 date arithmetic
- Final interest calculated via COMINTL0 CALC function: balance, rate, floor date to current date
- Total payoff = current balance + final interest
- Cumulative interest = existing accrued + final interest
- On update: balance set to 0, status to PD, payoff_date to current date
- Output shows original balance, final interest charge, and total payoff amount

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- WS-OUT-MESSAGE used as error flag throughout
- DB2 errors checked inline; COMINTL0 errors produce specific message
- IMS status checked after GU/ISRT

## Modernization Notes
- **Target Module:** vehicle (floor plan sub-module)
- **Target Endpoint:** POST /api/floor-plan/vehicles/{vin}/payoff
- **React Page:** FloorPlanPayoff
- **Key Considerations:** This should trigger automatically when a vehicle is sold. BigDecimal for interest calculation. Total payoff is a critical financial figure -- must be precise. Consider integration with accounting/GL posting. The payoff operation should be idempotent (prevent double payoff). The floor plan payoff often triggers a wire transfer to the lender -- consider workflow integration.
