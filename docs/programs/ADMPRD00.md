# ADMPRD00 — F&I Product Catalog Maintenance

## Overview
- **Program ID:** ADMPRD00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMF
- **Source:** cbl/online/adm/ADMPRD00.cbl
- **Lines of Code:** 926
- **Complexity:** Medium

## Purpose
Maintains the catalog of Finance & Insurance (F&I) products available for sale (extended warranty, GAP insurance, service contracts, paint protection, etc.). Stores product data in the SYSTEM_CONFIG table using a key prefix convention ('FI_PRODUCT_' + type code). Supports inquiry, add, update, and list operations with margin calculations.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADPRD (F&I Product Catalog Screen)
- **MFS Output (MOD):** ASPRDI00 (F&I Product Inquiry Response)
- **Message Format:** Input includes function (INQ/ADD/UPD/LST), product type code (4), product name (30), default term (3 months), retail price (10), cost (10), user ID. Output includes formatted retail/cost, calculated margin and margin percentage, config key display. List output shows up to 15 products.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SYSTEM_CONFIG | SELECT | Inquiry by config key (FI_PRODUCT_ + type) |
| AUTOSALE.SYSTEM_CONFIG | INSERT | Add new F&I product |
| AUTOSALE.SYSTEM_CONFIG | SELECT + UPDATE | Update: fetch old value for audit, then update |
| AUTOSALE.SYSTEM_CONFIG | SELECT (cursor) | List all keys matching LIKE 'FI_PRODUCT_%' (max 15) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format currency values |
| COMLGEL0 | Audit logging with old/new config values |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Config key convention:** Product data is stored with key = 'FI_PRODUCT_' + 4-char type code (e.g., 'FI_PRODUCT_EWTY').
- **Serialized value format:** Config value stores pipe-delimited data: NAME(30)|TERM(3)|RETAIL(10)|COST(10). Parsed via UNSTRING on read, built via STRING on write.
- **Valid product types (10):** EWTY (Extended Warranty), GAPI (GAP Insurance), SVCC (Service Contract), PPRT (Paint Protection), FPRT (Fabric Protection), TRST (Tire & Road), DNTC (Dent Care), KEYR (Key Replacement), WIND (Windshield), THFT (Theft Deterrent).
- **Pricing validation:** Retail price and cost must be > 0. Retail should be >= cost.
- **Margin calculation:** Margin = retail - cost. Margin % = (margin / retail) * 100.
- **Audit on update:** Retrieves old config value before update to log both old and new values.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLSYSCF — DCLGEN for SYSTEM_CONFIG table

### Error Handling
Standard SQLCODE evaluation with COMDBEL0. Duplicate key (-803) caught on insert. Not found (+100) on inquiry and update. List cursor handles empty result set with specific message.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/fi-products/{type}, POST /api/fi-products, PUT /api/fi-products/{type}, GET /api/fi-products
- **React Page:** FIProductCatalog
- **Key Considerations:** The approach of storing structured product data as pipe-delimited strings in a generic config table is a major technical debt item. In the modern system, F&I products should have their own dedicated table with proper columns for name, term, retail price, and cost. The 10-type product type table should become a database-driven enum. The margin calculation logic should move to the service layer.
