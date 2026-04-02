# SALTRD00 — Trade-In Vehicle Evaluation

## Overview
- **Program ID:** SALTRD00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALT
- **Source:** cbl/online/sal/SALTRD00.cbl
- **Lines of Code:** 799
- **Complexity:** High

## Purpose
Evaluates trade-in vehicles as part of a sales deal. Captures trade vehicle information (VIN, year, make, model, color, odometer, condition), optionally validates/decodes the VIN, calculates Actual Cash Value (ACV) based on condition code, allows over-allowance, captures payoff information, and recalculates the deal's net trade and amount financed. Inserts a TRADE_IN record linked to the deal.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLTD00 (Trade-In Response)
- **Message Format:** Input includes deal number (10), trade VIN (17), year (4), make (20), model (30), color (15), odometer (7), condition code (E/G/F/P), over-allowance amount (10), payoff amount (12), payoff bank (40), payoff account (20). Output shows trade vehicle details, VIN, odometer, condition code, base value, condition adjustment percentage, ACV, allowance, over-allowance, payoff amount, net trade (allowance - payoff), and payoff bank/account info.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.TRADE_IN | INSERT | Create trade-in record linked to deal |
| AUTOSALE.SALES_DEAL | SELECT | Read deal to associate trade-in |
| AUTOSALE.SALES_DEAL | UPDATE | Recalculate net trade and amount financed |
| AUTOSALE.PRICE_MASTER | SELECT | Look up base value for trade vehicle (by year/make/model) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN validation (check digit, format) |
| COMVINL0 | VIN decode (extract year, make, model from VIN) |
| COMFMTL0 | Currency formatting |
| COMLGEL0 | Audit log entry |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Condition-based ACV calculation:**
  - E (Excellent): 100% of base value
  - G (Good): 85% of base value
  - F (Fair): 70% of base value
  - P (Poor): 55% of base value
- **Base value source:** Looked up from PRICE_MASTER using the trade vehicle's year/make/model. If not found, uses manual entry.
- **Allowance:** ACV + over-allowance amount. Over-allowance is an amount above ACV that the dealer offers to close the deal.
- **Net trade:** Allowance - payoff amount. Can be negative if payoff exceeds allowance ("upside down" trade).
- **Payoff tracking:** Captures payoff amount, bank name, and account number for lien payoff processing.
- **VIN processing:** If trade VIN provided, COMVALD0 validates the VIN format and check digit. COMVINL0 decodes year/make/model from the VIN. Decoded values can be used instead of manual entry.
- **Deal recalculation:** After inserting trade-in, recalculates the deal's amount financed as: total price - down payment - net trade.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLTRDEIN — DCLGEN for TRADE_IN table
- DCLPRICE — DCLGEN for PRICE_MASTER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates deal exists. VIN validation failure is a warning, not a blocking error (manual entry still allowed). Condition code must be E, G, F, or P. DB errors via COMDBEL0.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** POST /api/deals/{dealNumber}/trade-in
- **React Page:** TradeInEvaluation
- **Key Considerations:** The condition-based ACV calculation should be enhanced with actual market data integration (KBB, NADA, etc.) in the modern system, with the condition adjustment as one factor. The VIN decode should integrate with a real VIN decoder API. The "upside down" trade (negative equity) needs clear UI handling. The over-allowance concept represents dealer negotiation flexibility and should be tracked for profitability analysis. The payoff information may require integration with lender APIs for real-time payoff quotes.
