# STKHLD00 — Vehicle Hold/Release

## Overview
- **Program ID:** STKHLD00
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKHLD00.cbl
- **Lines of Code:** 358
- **Complexity:** Medium

## Purpose
Places a vehicle on hold (customer deposit or manager hold) or releases a held vehicle back to available status. Validates status transitions and updates both VEHICLE and STOCK_POSITION tables via COMSTCK0.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKH00
- **Message Format:** Input: function (HOLD/RLSE), VIN, hold reason. Output: vehicle details, old/new status, on-hand/on-hold counts.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Get current vehicle status and details |
| AUTOSALE.STOCK_POSITION | UPDATE (via COMSTCK0) | Update hold/available counts |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock count update (HOLD or RLSE function) |
| COMLGEL0 | Audit logging |

### Key Business Logic
- Function must be HOLD or RLSE.
- VIN is required. Hold reason is required for HOLD function.
- For HOLD: vehicle must be in AV (Available) status.
- For RLSE (Release): vehicle must be in HD (On Hold) status.
- Delegates actual status change and stock count update to COMSTCK0.
- COMSTCK0 return code <= 4 is success/warning; > 4 is error.
- Audit log records old status, new status, and hold reason.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- DCLVEHCL

### Error Handling
- Invalid function returns "FUNCTION MUST BE HOLD OR RLSE".
- Vehicle not found returns error.
- Invalid status transition returns descriptive error.
- COMSTCK0 failures reported via its return message.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/{vin}/hold, DELETE /api/vehicles/{vin}/hold
- **React Page:** StockDashboard
- **Key Considerations:** Hold/release is a simple status toggle with validation. The COMSTCK0 dependency can be replaced with direct stock position updates. Hold reason should be stored for audit purposes.
