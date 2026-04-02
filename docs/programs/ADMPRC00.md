# ADMPRC00 — Pricing Master Maintenance

## Overview
- **Program ID:** ADMPRC00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMP
- **Source:** cbl/online/adm/ADMPRC00.cbl
- **Lines of Code:** 853
- **Complexity:** High

## Purpose
Maintains the PRICE_MASTER table for vehicle pricing by year/make/model with effective date logic. Supports inquiry (showing current effective price plus up to 5 historical prices), add, and update operations. Validates MSRP > invoice, calculates holdback from percentage if amount not provided, and computes margin and margin percentage.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADPRC (Pricing Maintenance Screen)
- **MFS Output (MOD):** ASPRCI00 (Pricing Inquiry Response)
- **Message Format:** Input includes function (INQ/ADD/UPD), model year (4), make code (3), model code (6), MSRP (12), invoice (12), holdback amount/percentage, destination fee, advertising fee, effective/expiry dates, user ID. Output includes formatted currency fields, calculated margin and margin percentage, and up to 5 price history entries with effective/expiry dates and MSRP/invoice.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.PRICE_MASTER | SELECT | Get current effective price (where effective_date <= today and expiry_date >= today or null) |
| AUTOSALE.PRICE_MASTER | SELECT (cursor) | Fetch up to 5 historical price records ordered by effective_date desc |
| AUTOSALE.PRICE_MASTER | INSERT | Add new price record |
| AUTOSALE.PRICE_MASTER | UPDATE | Update existing price by year/make/model/effective_date |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format currency values |
| COMLGEL0 | Audit logging with MSRP and invoice values |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **MSRP > Invoice rule:** MSRP must always be greater than invoice price.
- **Holdback calculation:** If holdback amount is not provided but percentage is, calculates holdback = MSRP * percentage / 100. If neither provided, defaults to 3% of MSRP.
- **Holdback reasonableness:** Holdback percentage must not exceed 10% of MSRP.
- **Margin calculation:** Margin = MSRP - Invoice. Margin percentage = (Margin / MSRP) * 100.
- **Effective date logic:** Inquiry selects the row where effective_date <= CURRENT DATE and expiry_date is null or >= CURRENT DATE, ordered by effective_date descending, first row only.
- **Price history:** After displaying current price, opens a cursor to fetch up to 5 historical price records for the same year/make/model.
- **Nullable expiry:** Expiry date supports null (meaning "current/no expiry").

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLPRICE — DCLGEN for PRICE_MASTER table

### Error Handling
Standard SQLCODE pattern with COMDBEL0. Duplicate key (-803) caught on insert with "already exists for this date" message. Update matches on year/make/model/effective_date composite key.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/pricing/{year}/{make}/{model}, POST /api/pricing, PUT /api/pricing/{year}/{make}/{model}/{effectiveDate}, GET /api/pricing/{year}/{make}/{model}/history
- **React Page:** PricingManagement
- **Key Considerations:** The effective date / expiry date pattern for price versioning is a temporal data model that should be preserved or migrated to a proper SCD Type 2 pattern. The holdback auto-calculation logic is business-critical and must be preserved. The margin calculation should move to a service layer. The price history query is a natural candidate for a separate /history endpoint.
