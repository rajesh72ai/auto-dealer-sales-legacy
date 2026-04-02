# FINPRD00 — F&I Product Selection

## Overview
- **Program ID:** FINPRD00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNPR
- **Source:** cbl/online/fin/FINPRD00.cbl
- **Lines of Code:** 656
- **Complexity:** High

## Purpose
Displays a menu of available F&I (Finance and Insurance) products for a deal. Supports multi-select of 10 products (extended warranty, GAP, paint protection, fabric guard, theft deterrent, maintenance, tire/wheel, dent repair, key replacement, LoJack). Calculates total F&I gross, inserts FINANCE_PRODUCT records for each selected product, and updates SALES_DEAL back gross and total gross.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: deal number (10), selections (30, space-separated 3-char codes). Output: product catalog with selection markers, totals (retail, cost, profit), product count.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Validate deal, get front gross |
| AUTOSALE.SALES_DEAL | UPDATE | Set BACK_GROSS and recalculate TOTAL_GROSS |
| AUTOSALE.FINANCE_PRODUCT | SELECT | Get next product sequence number |
| AUTOSALE.FINANCE_PRODUCT | INSERT | Insert each selected product |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Field formatting |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- **Hard-coded product catalog** (10 entries) with code, name, term, mileage, retail price, dealer cost, and profit:
  - EXW: Extended Warranty (36mo/12K mi, $1995 retail, $895 cost, $1100 profit)
  - GAP: GAP Insurance (36mo, $895/$325/$570)
  - PPT: Paint Protection (60mo, $599/$125/$474)
  - FBR: Fabric Protection (60mo, $399/$75/$324)
  - THF: Theft Deterrent (60mo, $695/$195/$500)
  - MNT: Maintenance Plan (36mo/50K, $799/$375/$424)
  - TIR: Tire and Wheel (36mo/50K, $599/$185/$414)
  - DNT: Dent Repair (36mo, $399/$95/$304)
  - KEY: Key Replacement (60mo, $299/$45/$254)
  - LOJ: LoJack GPS (48mo, $995/$450/$545)
- Selection parsing: INSPECT/TALLYING to find 3-char product codes in selection string
- Product sequence auto-incremented via MAX(PRODUCT_SEQ) + 1
- Total gross recalculation: TOTAL_GROSS = FRONT_GROSS + F&I PROFIT (back gross)
- Each selected product inserted individually with EXIT PERFORM on first DB2 error

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT
- DCLSLDEL (SALES_DEAL DCLGEN)
- DCLFINPR (FINANCE_PRODUCT DCLGEN)

### Error Handling
- Return code pattern: 0=success, 8=validation, 16=system error
- DB2 insert errors terminate the product insertion loop
- If no products selected, shows catalog only (informational)
- IMS ISRT failure sets abend code 'FNPR'

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** POST /api/finance/deals/{dealNumber}/products
- **React Page:** FAndIProductSelector
- **Key Considerations:** The hard-coded product catalog should become a database-driven product configuration table. Retail/cost/profit amounts should use BigDecimal. The multi-select pattern maps to an array of product codes in the request body. Gross profit recalculation (front + back) is a critical accounting operation that should be atomic. Consider real-time pricing based on vehicle/customer rather than flat rates.
