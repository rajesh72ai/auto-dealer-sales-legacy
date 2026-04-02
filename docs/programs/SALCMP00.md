# SALCMP00 — Sale Completion / Closing

## Overview
- **Program ID:** SALCMP00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALC
- **Source:** cbl/online/sal/SALCMP00.cbl
- **Lines of Code:** 664
- **Complexity:** High

## Purpose
Handles the final closing and delivery of a vehicle sale. Validates a delivery checklist (deal approved, insurance verified, down payment received, credit/finance approved if not cash, trade title received if trade-in). Updates deal status to DL (Delivered), sets delivery date and final amounts, marks the vehicle as SD (Sold), and updates stock position counts (decrements on-hand, increments sold MTD/YTD).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLCP00 (Completion Response)
- **Message Format:** Input includes deal number (10), delivery date (10), down payment method (CA/CK/CC/WR), down payment amount (12), insurance OK flag (1), trade title received flag (1). Output shows deal header, delivery checklist with pass/fail indicators for each item, delivery date, down payment amount, final total, financed amount, and vehicle status.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Read deal details and validate status (AP or FI) |
| AUTOSALE.SALES_DEAL | UPDATE | Set status to DL, delivery date, final amounts |
| AUTOSALE.VEHICLE | UPDATE | Set vehicle status to SD (Sold) |
| AUTOSALE.STOCK_POSITION | UPDATE (via COMSTCK0) | Decrement on-hand, increment sold MTD/YTD |
| AUTOSALE.TRADE_IN | SELECT | Check if trade-in exists for trade title verification |
| AUTOSALE.FINANCE_APP | SELECT | Check finance approval status |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMSTCK0 | Stock update — SOLD function |
| COMSEQL0 | Sequence number generator |
| COMLGEL0 | Audit log entry |
| COMDBEL0 | DB2 error handling |
| COMFMTL0 | Currency formatting |

### Key Business Logic
- **Delivery checklist (5 items):**
  1. Deal must be in AP (Approved) or FI (F&I complete) status.
  2. Insurance must be verified (insurance OK flag = 'Y').
  3. Down payment must be received (amount > 0 with valid method).
  4. Credit/finance must be approved (checked from FINANCE_APP table — not required for cash deals).
  5. Trade title received (only checked if trade-in exists on the deal).
- **Checklist display:** Each item shows [OK] or [--] indicator in output.
- **All checks must pass:** If any checklist item fails, WS-CHECKLIST-OK is set to 'N' and completion is blocked.
- **Down payment methods:** CA (Cash), CK (Check), CC (Credit Card), WR (Wire Transfer).
- **Vehicle status transition:** Vehicle status changes to SD (Sold).
- **Stock update:** COMSTCK0 called with SOLD function to adjust stock position.
- **Final amounts:** Delivery date, down payment, final total, and financed amount (total minus down payment) are set on the deal.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates deal exists and is in correct status. Checklist failures prevent completion with descriptive indicators showing which items are incomplete. DB errors via COMDBEL0.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** POST /api/deals/{dealNumber}/complete
- **React Page:** DealCompletion
- **Key Considerations:** The delivery checklist pattern is a workflow gate that should be modeled as a business rules engine or checklist service. Each checklist item involves cross-table validation and should be individually testable. The vehicle status update and stock position changes should be within the same transaction. The down payment method and amount should be validated more rigorously (e.g., credit card authorization). The "warranty registration" and "registration data assembly" mentioned in the header comments suggest downstream integrations that may need event-driven triggers.
