# SALQOT00 — Deal Worksheet / Quote Generation

## Overview
- **Program ID:** SALQOT00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALQ
- **Source:** cbl/online/sal/SALQOT00.cbl
- **Lines of Code:** 1173
- **Complexity:** High

## Purpose
Creates a complete deal worksheet/quote by assembling all deal components. Receives customer ID, VIN, salesperson ID, and deal type; validates all entities; builds a comprehensive worksheet with vehicle price, options, destination fee, trade-in, incentives, itemized tax, and all fees. Calculates total price, down payment, amount financed, and front gross. Generates a deal number via sequence and inserts both SALES_DEAL (status WS = Worksheet) and DEAL_LINE_ITEM records.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLDL00 (Deal Worksheet Response)
- **Message Format:** Input includes customer ID (9), VIN (17), salesperson ID (8), deal type (R/L/F/W), dealer code (5), and down payment amount (12). Output is a full worksheet showing deal number, customer name/ID, vehicle year/make/model/VIN, MSRP, options total, destination fee, subtotal, discount, rebates/incentives, net trade-in, state/county/city tax breakdown, doc/title/reg fees, total price, down payment, amount financed, and front gross with margin.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | INSERT | Create new deal record with status WS |
| AUTOSALE.DEAL_LINE_ITEM | INSERT | Create line items for each deal component |
| AUTOSALE.CUSTOMER | SELECT | Validate customer exists, get name and address for tax |
| AUTOSALE.VEHICLE | SELECT | Validate VIN, get year/make/model, check availability |
| AUTOSALE.SYSTEM_USER | SELECT | Validate salesperson exists and is active |
| AUTOSALE.PRICE_MASTER | SELECT (via COMPRCL0) | Get MSRP, invoice, holdback, dest fee |
| AUTOSALE.VEHICLE_OPTION | SELECT | Get total options value for the VIN |
| AUTOSALE.TAX_RATE | SELECT (via COMTAXL0) | Calculate state/county/city tax |
| AUTOSALE.TRADE_IN | SELECT | Get existing trade-in for deal |
| AUTOSALE.INCENTIVE_APPLIED | SELECT | Get applied incentives total |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMPRCL0 | Vehicle pricing lookup (MSRP, invoice, holdback, dest fee, adv fee) |
| COMTAXL0 | Tax calculation (state, county, city breakdown with doc/title/reg fees) |
| COMSEQL0 | Sequence number generator for deal number |
| COMFMTL0 | Currency formatting |
| COMLGEL0 | Audit log entry |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Deal types:** R (Retail), L (Lease), F (Fleet), W (Wholesale).
- **Entity validation:** Customer must exist, vehicle must exist and be in available status, salesperson must be an active user at the dealer.
- **Deal number generation:** COMSEQL0 called with 'DEAL' sequence key to get next deal number.
- **Worksheet calculation:**
  - SUBTOTAL = MSRP + options + destination fee
  - NET_PRICE = subtotal - discount - rebates
  - TAX = COMTAXL0(net_price, state, county, city)
  - TOTAL_FEES = doc_fee + title_fee + reg_fee
  - TOTAL_PRICE = net_price + tax + total_fees
  - NET_TRADE = trade_allowance - trade_payoff
  - AMOUNT_FINANCED = total_price - down_payment - net_trade
  - FRONT_GROSS = selling_price - invoice - holdback adjustments
- **Line items:** Individual DEAL_LINE_ITEM records created for vehicle price, each option, dest fee, each tax component, each fee, trade-in, each incentive — providing full deal decomposition.
- **Status:** New deal created with status WS (Worksheet) — indicating it is a quote, not yet a committed deal.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLDLITM — DCLGEN for DEAL_LINE_ITEM table
- DCLCUSTM — DCLGEN for CUSTOMER table
- DCLVEHCL — DCLGEN for VEHICLE table
- DCLPRICE — DCLGEN for PRICE_MASTER table
- DCLVHOPT — DCLGEN for VEHICLE_OPTION table
- DCLTRDEIN — DCLGEN for TRADE_IN table
- DCLSYUSR — DCLGEN for SYSTEM_USER table

### Error Handling
Uses WS-RETURN-CODE pattern. Extensive validation before any insert: customer not found, vehicle not available, salesperson invalid, pricing not found. Each validation produces a specific error message. DB errors via COMDBEL0. Duplicate deal number caught (-803).

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** POST /api/deals
- **React Page:** DealWorksheet
- **Key Considerations:** This is the most complex program in the sales module, touching 10+ tables and calling 6 subroutines. It should be decomposed into multiple service calls: a DealCreationService that orchestrates VehiclePricingService, TaxCalculationService, IncentiveService, and TradeInService. The deal calculation logic (subtotal, tax, total, financed) should be a reusable DealCalculator class shared with SALNEG00. The line item decomposition pattern is excellent for audit and should be preserved. The sequence number generation should use database sequences. The deal type determines different downstream processing paths (retail vs. lease vs. fleet) that should be modeled as a strategy pattern.
