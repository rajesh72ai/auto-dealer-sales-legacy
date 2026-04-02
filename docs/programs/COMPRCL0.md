# COMPRCL0 — Vehicle Pricing Engine

## Overview
- **Program ID:** COMPRCL0
- **Type:** Common Module
- **Source:** cbl/common/COMPRCL0.cbl
- **Lines of Code:** 628
- **Complexity:** High

## Purpose
Looks up base pricing from the PRICE_MASTER DB2 table and calculates all pricing components for a vehicle including MSRP, invoice, holdback, gross profit, margin percentage, and complete deal pricing with tax (via COMTAXL0).

## Technical Details

### Entry Point / Call Interface
Called via `CALL 'COMPRCL0' USING LK-PRC-INPUT-AREA LK-PRC-RESULT-AREA LK-PRC-RETURN-CODE LK-PRC-ERROR-MSG`.

Function codes: MSRP, INVP (invoice), GROS (gross profit), MRGN (margin %), DEAL (complete deal).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT | Look up vehicle by VIN to get year/make/model |
| AUTOSALE.PRICE_MASTER | SELECT | Look up effective base pricing by year/make/model |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMTAXL0 | Tax calculation for DEAL function |

### Key Business Logic
- **Vehicle resolution:** If VIN provided, looks up VEHICLE table for model year, make code, model code. Otherwise uses direct input.
- **Effective pricing:** Queries PRICE_MASTER with effective date logic (EFFECTIVE_DATE <= today AND (EXPIRY_DATE IS NULL OR >= today)). Ordered by EFFECTIVE_DATE DESC, FETCH FIRST 1 ROW.
- **Pricing components:** Base MSRP, destination fee, advertising fee, holdback (fixed amount or percentage of invoice), invoice price.
- **Total MSRP:** Base MSRP + destination fee.
- **Total Invoice:** Base invoice + destination + advertising fee.
- **Dealer Cost:** Total invoice - holdback.
- **Front Gross:** Selling price - total invoice.
- **Back Gross:** Holdback amount.
- **Total Gross:** Front + back gross.
- **Margin %:** Total gross / selling price * 100.
- **DEAL function:** Calculates gross/margin, then calls COMTAXL0 for tax/fees, then: Deal Total = Selling Price + Tax + Fees - Trade.

### Copybooks Used
- WSSQLCA
- DCLPRICE (PRICE_MASTER DCLGEN)
- DCLVEHCL (VEHICLE DCLGEN)

### Input/Output
- **Input:** Function, VIN or year/make/model, selling price, trade amount, doc fee, state/county/city codes
- **Output:** Full pricing breakdown: MSRP, invoice, holdback, dealer cost, gross, margin, tax, fees, deal total

## Modernization Notes
- **Target:** Pricing engine / Deal calculator service
- **Key considerations:** The front-gross/back-gross distinction is an important dealer concept (customers see front gross; holdback is hidden). The effective-date pricing lookup supports price changes over time. The COMTAXL0 call for deal pricing creates a dependency chain.
- **Dependencies:** Calls COMTAXL0 for tax calculation. Uses PRICE_MASTER and VEHICLE tables.
