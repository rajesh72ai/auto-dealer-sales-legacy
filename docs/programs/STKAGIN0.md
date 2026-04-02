# STKAGIN0 — Stock Aging Analysis

## Overview
- **Program ID:** STKAGIN0
- **Module:** STK — Stock Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** (via DLITCBL entry)
- **Source:** cbl/online/stk/STKAGIN0.cbl
- **Lines of Code:** 488
- **Complexity:** High

## Purpose
Calculates days on lot for every vehicle at a dealer (current date minus receive date). Updates VEHICLE.DAYS_IN_STOCK field. Buckets vehicles into aging ranges: 0-30, 31-60, 61-90, 91-120, 120+ days. Provides summary by bucket with count, total value, and average value. Flags vehicles approaching floor plan curtailment (75+ days).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASSTKG00
- **Message Format:** Input: dealer code. Output: processed/updated counts, 5 aging bucket lines (name, count, total value, avg value), curtailment warning count.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT (cursor) | Read all active vehicles for dealer with receive dates |
| AUTOSALE.VEHICLE | UPDATE | Update DAYS_IN_STOCK when calculated value differs |
| AUTOSALE.PRICE_MASTER | JOIN | Get invoice price for value calculations |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDTEL0 | Date utility - calculate days between receive date and current date |
| COMFMTL0 | Currency formatting for total and average values |

### Key Business Logic
- Dealer code is required.
- Cursor selects vehicles with status AV, DM, LN, HD, or AL that have a non-null receive date, ordered by receive date.
- For each vehicle, calls COMDTEL0 with 'AGED' function to compute days between receive date and current date.
- Falls back to existing DAYS_IN_STOCK if date calculation fails.
- Updates DAYS_IN_STOCK on vehicle record only when calculated value differs.
- Assigns each vehicle to one of 5 aging buckets and accumulates count and total invoice value.
- Curtailment warning threshold: 75 days (WS-CURTAIL-WARNING). Curtailment threshold: 90 days.
- Builds output with formatted currency values via COMFMTL0 and average value per bucket.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- DB2 cursor open error returns error message.
- Non-zero SQLCODE during fetch sets error message and stops processing.
- "NO ACTIVE VEHICLES FOUND FOR DEALER" if no vehicles match.

## Modernization Notes
- **Target Module:** vehicle (stock analytics)
- **Target Endpoint:** GET /api/stock/aging/{dealerCode}
- **React Page:** StockDashboard
- **Key Considerations:** Aging calculation can be done in SQL (DAYS(CURRENT_DATE) - DAYS(RECEIVE_DATE)). The batch-update of DAYS_IN_STOCK could become a scheduled job or computed column. Curtailment thresholds should be configurable.
