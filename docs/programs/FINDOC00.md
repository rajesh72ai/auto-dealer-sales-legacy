# FINDOC00 — Finance Document Generation

## Overview
- **Program ID:** FINDOC00
- **Module:** FIN
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** FNDC
- **Source:** cbl/online/fin/FINDOC00.cbl
- **Lines of Code:** 934
- **Complexity:** High

## Purpose
Generates document data for finance closing: Retail Installment Contract (loan), Lease Agreement (lease), or Cash Receipt (cash). Pulls all deal information including customer, vehicle, pricing, trade-in, finance terms, and F&I products. Formats buyer/seller info, vehicle description, itemized pricing, and payment terms into a multi-segment output message for print.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard WSMSGFMT message format
- **MFS Output (MOD):** Standard WSMSGFMT message format
- **Message Format:** Input: deal number (10). Output: multi-section document with seller info, buyer info, vehicle description, itemized pricing, finance terms, F&I products list.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Full deal details (25+ columns) |
| AUTOSALE.CUSTOMER | SELECT | Buyer name, address |
| AUTOSALE.DEALER | SELECT | Seller name, address |
| AUTOSALE.VEHICLE | SELECT | VIN, year, make, stock number, odometer |
| AUTOSALE.MODEL_MASTER | SELECT | Model name (joined with vehicle) |
| AUTOSALE.FINANCE_APP | SELECT | Finance type, approved terms, monthly payment |
| AUTOSALE.LEASE_TERMS | SELECT | Lease-specific terms (residual, money factor, etc.) |
| AUTOSALE.FINANCE_PRODUCT | SELECT (cursor) | F&I products for the deal (up to 5) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLONL0 | Loan recalculation for document terms |
| COMLESL0 | Lease recalculation for lease documents |
| COMFMTL0 | Field formatting |
| COMDBEL0 | DB2 error handler |

### Key Business Logic
- Document title determined by finance type: L="RETAIL INSTALLMENT CONTRACT", S="MOTOR VEHICLE LEASE AGREEMENT", C="CASH SALE RECEIPT"
- Pricing itemization: vehicle price, options, destination fee, discounts/rebates, net trade allowance, taxes (state+county+city), fees (doc+title+reg), total price, down payment, amount financed
- Loan terms: recalculates using approved APR via COMLONL0 to get monthly payment, total payments, finance charge
- Lease terms: fetches from LEASE_TERMS table (residual, money factor, adjusted cap cost, finance charge)
- Cash: no finance terms section displayed
- F&I products: cursor-based fetch of up to 5 products with name and retail price
- Customer/dealer address formatting uses STRING with delimiters for city/state/zip

### Copybooks Used
- WSSQLCA, WSIOPCB, WSMSGFMT
- DCLSLDEL (SALES_DEAL), DCLFINAP (FINANCE_APP), DCLCUSTM (CUSTOMER)
- DCLVEHCL (VEHICLE), DCLMODEL (MODEL_MASTER), DCLTRDEIN (TRADE_IN)
- DCLLSTRM (LEASE_TERMS), DCLFINPR (FINANCE_PRODUCT), DCLDEALR (DEALER)

### Error Handling
- Return code pattern: 0=success, 8=validation, 16=system error
- DB2 errors through COMDBEL0
- If no finance app found, defaults to cash document
- IMS ISRT failure sets abend code 'FNDC'

## Modernization Notes
- **Target Module:** finance
- **Target Endpoint:** GET /api/finance/documents/{dealNumber}
- **React Page:** FinanceDocumentViewer
- **Key Considerations:** This is the most data-intensive program in the FIN module, joining 9 tables. In a modern architecture, this becomes a document assembly service that aggregates data from multiple microservices. Consider PDF generation (e.g., via a template engine). The pricing itemization logic is critical for regulatory compliance (TILA disclosures). BigDecimal required for all monetary fields. The cursor-based F&I product fetch maps to a simple sub-query or array field.
