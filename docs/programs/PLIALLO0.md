# PLIALLO0 — Vehicle Allocation Engine

## Overview
- **Program ID:** PLIALLO0
- **Module:** PLI
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** PLAL
- **Source:** cbl/online/pli/PLIALLO0.cbl
- **Lines of Code:** 670
- **Complexity:** High

## Purpose
Assigns produced vehicles to dealer orders based on priority. Supports manual allocation (specific VIN to specific dealer), auto-allocation (by model to best-fit dealer), and inquiry. Checks dealer allocation priority (SYSTEM_CONFIG), region matching, and current inventory vs maximum. Updates PRODUCTION_ORDER.ALLOCATED_DEALER and VEHICLE.DEALER_CODE, setting status to AL (Allocated).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: function (2: MA/AU/IQ), VIN (17), dealer code (5), model year (4), make (3), model (6), region (4), priority override (1). Output: VIN, dealer, year/make/model, priority, region, on-hand/max inventory, status change, auto-allocation count.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Verify vehicle exists, status=PR |
| AUTOSALE.VEHICLE | UPDATE | Set dealer code and status=AL |
| AUTOSALE.PRODUCTION_ORDER | UPDATE | Set allocated dealer and status=AL |
| AUTOSALE.DEALER | SELECT (cursor) | Candidate dealers for auto-allocation |
| AUTOSALE.SYSTEM_CONFIG | JOIN | Allocation priority and max inventory per dealer |
| AUTOSALE.STOCK_POSITION | JOIN | Current on-hand count by model |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock position update (ALOC function) |
| COMLGEL0 | Audit logging |

### Key Business Logic
- **Manual allocation**: verifies vehicle status=PR, checks dealer inventory capacity, updates both PRODUCTION_ORDER and VEHICLE tables, calls COMSTCK0 for stock update
- **Auto-allocation**: opens cursor joining DEALER + SYSTEM_CONFIG (priority) + STOCK_POSITION (on-hand) + SYSTEM_CONFIG (max inventory), ordered by priority ASC then on-hand ASC; selects first eligible dealer (under max inventory); bulk-updates all unallocated vehicles of the model
- **Inventory check**: warns (RC=4) if dealer at or over max inventory but proceeds
- Auto-allocation count obtained from SQLERRD(3) after bulk UPDATE
- Both VEHICLE and PRODUCTION_ORDER tables updated in tandem

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT

### Error Handling
- Return code pattern: 0=success, 4=warning (over capacity), 8=validation, 12=DB2 error, 16=IMS error
- IMS ISRT failure sets abend code 'PLIALLO0'
- Auto-allocation cursor properly opened/closed in all paths

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** POST /api/vehicles/allocate (manual), POST /api/vehicles/auto-allocate (batch)
- **React Page:** VehicleAllocationDashboard
- **Key Considerations:** The allocation priority system (SYSTEM_CONFIG) should become a proper configuration service. The auto-allocation algorithm (priority + capacity) is a good candidate for an allocation optimization service. The bulk update pattern (SQLERRD(3) for row count) needs equivalent in modern SQL. Consider event-driven architecture for allocation notifications to dealers. Stock position updates via COMSTCK0 should be eventual consistency or saga pattern.
