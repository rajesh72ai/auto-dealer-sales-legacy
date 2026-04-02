# VEHAGE00 — Inventory Aging Display

## Overview
- **Program ID:** VEHAGE00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHAG
- **Source:** cbl/online/veh/VEHAGE00.cbl
- **Lines of Code:** 731
- **Complexity:** High

## Purpose
Shows aging buckets for a dealer: 0-30 days, 31-60, 61-90, 90+ days. Calculates from VEHICLE.RECEIVE_DATE to current date. Summary mode shows count and total value per bucket. Detail mode lists vehicles in a selected bucket. Highlights vehicles over 90 days as aged stock.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT shared format)
- **MFS Output (MOD):** (via WSMSGFMT shared format)
- **Message Format:** Input: function (SM=Summary/DT=Detail), dealer code, bucket selection (1-4). Output: 4 bucket summary lines (count, value, avg days, percent), total line, and up to 8 detail vehicle lines.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT (cursor CSR_VEH_AGING) | Read all active vehicles for aging summary |
| AUTOSALE.VEHICLE | SELECT (cursor CSR_VEH_AGED_DTL) | Read vehicles in specific aging bucket |
| AUTOSALE.PRICE_SCHEDULE | (referenced) | Referenced for pricing data |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDTEL0 | Date calculation - compute days between receive date and current date (AGED function) |
| COMFMTL0 | Currency formatting |
| COMPRCL0 | Get invoice price for value calculation (INVC function) |

### Key Business Logic
- Two modes: SM (Summary) and DT (Detail). Summary is default.
- Vehicles with status AV, HD, or AL and non-null receive date are included.
- For each vehicle, calls COMDTEL0 to compute actual days aged; falls back to DAYS_IN_STOCK if calculation fails.
- Calls COMPRCL0 to get invoice price per vehicle.
- Four aging buckets: 0-30, 31-60, 61-90, 90+ days.
- Per bucket: count, total invoice value, average days, percentage of total.
- Detail mode: fetches up to 8 vehicles in the selected bucket with VIN, year, model, color, days, invoice, and aged alert flag ("**AG*" for 90+ days).
- Warning message generated when any vehicles exceed 90 days.

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT

### Error Handling
- IMS GU failure sets return code 16.
- Dealer code required; bucket required for detail mode.
- DB2 cursor errors set return code 12.
- "NO VEHICLES WITH RECEIVE DATE IN INVENTORY" if no vehicles found.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** GET /api/vehicles/aging/{dealerCode}?bucket=
- **React Page:** StockDashboard
- **Key Considerations:** Aging calculation can be performed in SQL directly. Invoice price lookup via COMPRCL0 can be replaced with a JOIN. The 8-vehicle detail limit should become paginated. Aged stock warnings should be configurable thresholds.
