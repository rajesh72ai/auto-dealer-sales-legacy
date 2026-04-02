# SALNEG00 — Price Negotiation

## Overview
- **Program ID:** SALNEG00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALN
- **Source:** cbl/online/sal/SALNEG00.cbl
- **Lines of Code:** 903
- **Complexity:** High

## Purpose
Implements the price negotiation desk for sales deals. Displays MSRP, invoice (manager only), and current offer with full deal financials. Allows counter offers, discount by amount or percentage, and recalculates all deal totals on each interaction. Shows gross profit and margin percentage (manager view only, controlled by user type). Supports manager desk notes visible to salesperson. Updates deal pricing and status to NE (Negotiating).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLNG00 (Negotiation Response)
- **Message Format:** Input includes deal number (10), counter offer amount (12), discount amount (12), discount percentage (6), desk notes (200), and action (VW=view, CO=counter offer, DS=discount). Output shows deal header with status, MSRP, invoice (marked "MGR ONLY"), current offer, discount applied, rebates, net trade-in, total tax, total fees, total price, front gross with margin percentage (marked "MGR ONLY"), and desk notes.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Read current deal pricing and details |
| AUTOSALE.SALES_DEAL | UPDATE | Update with new pricing after counter/discount |
| AUTOSALE.SYSTEM_USER | SELECT | Check user type for manager-only fields |
| AUTOSALE.CUSTOMER | SELECT | Get customer info for tax lookup |
| AUTOSALE.TAX_RATE | SELECT (via COMTAXL0) | Recalculate tax on new price |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMPRCL0 | Vehicle pricing lookup (MSRP, invoice) |
| COMTAXL0 | Tax calculation on adjusted price |
| COMFMTL0 | Currency formatting |
| COMLGEL0 | Audit log for price changes |

### Key Business Logic
- **Role-based visibility:** Invoice price and front gross/margin are displayed only when user type is M (Manager) or above. These fields are marked "** MGR ONLY **" in the output layout.
- **Counter offer (CO):** Replaces the current vehicle price with the counter offer amount. Recalculates all downstream totals.
- **Discount (DS):** Can be applied by amount or percentage. Discount amount applied directly; percentage calculated from current price. Both update the deal's discount field.
- **Full recalculation:** On each counter/discount: SUBTOTAL = vehicle price + options + dest fee. TOTAL = subtotal - discount - rebates + tax + fees. FINANCED = total - down payment - net trade.
- **Front gross calculation:** Front gross = selling price - invoice cost. Margin % = (gross / selling price) * 100.
- **Desk notes:** Manager can enter notes (200 chars) that are stored on the deal and visible to the salesperson on subsequent views.
- **Status management:** Deal status set to NE (Negotiating) during price negotiation.
- **Tax recalculation:** Tax is recalculated via COMTAXL0 on each price change, using customer's state/county/city.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLSYUSR — DCLGEN for SYSTEM_USER table
- DCLCUSTM — DCLGEN for CUSTOMER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates deal exists and is in a negotiable status. Counter offer amount must be positive. Discount cannot exceed current price. DB errors via standard pattern.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** GET /api/deals/{dealNumber}/negotiation, POST /api/deals/{dealNumber}/counter-offer, POST /api/deals/{dealNumber}/discount
- **React Page:** DealNegotiation
- **Key Considerations:** The role-based field visibility (invoice, gross) should be enforced at the API level, not just the UI. The deal recalculation logic is shared with SALQOT00 and SALINC00 and should be extracted into a DealCalculationService. The desk notes feature maps to a real-time collaboration feature in the modern UI. The counter offer and discount should be logged as negotiation history for analytics. The tax recalculation on each price change is computationally expensive and may benefit from caching or deferred calculation.
