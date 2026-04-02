# CUSHIS00 — Customer Purchase History

## Overview
- **Program ID:** CUSHIS00
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSHI
- **Source:** cbl/online/cus/CUSHIS00.cbl
- **Lines of Code:** 516
- **Complexity:** Medium

## Purpose
Displays a customer's purchase history by querying SALES_DEAL joined with VEHICLE. Shows deal date, VIN, year/make/model, deal type, sale price, and trade-in allowance for up to 10 past deals. Computes summary statistics: total purchases, total amount spent, and average deal value. Identifies repeat buyer status (more than 1 purchase).

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input via WSMSGFMT
- **MFS Output (MOD):** Purchase History screen
- **Message Format:** Input includes function (IQ=inquiry) and customer ID (9). Output shows customer name/ID, repeat buyer status, column headers, up to 10 deal detail lines (date, VIN, year/make/model, deal type, sale price, trade-in), and summary section with total purchases, total spent, and average deal value.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | SELECT | Fetch customer name for display |
| AUTOSALE.SALES_DEAL | SELECT (cursor) | Fetch deals with status CL/DL/AP, joined with VEHICLE |
| AUTOSALE.VEHICLE | JOIN | Get year/make/model for each deal's VIN |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format currency values and dates |
| COMDTEL0 | Date utilities |

### Key Business Logic
- **Deal filter:** Only shows deals with status CL (Closed), DL (Delivered), or AP (Approved) — excludes cancelled, pending, and worksheet deals.
- **Cursor:** CSR_PURCH_HIST joins SALES_DEAL with VEHICLE on VIN, filters by customer ID and deal status, ordered by deal date descending (most recent first).
- **Max 10 deals displayed:** Fetches up to 10 rows from the cursor.
- **Summary calculation:** Total purchases = count of fetched deals. Total spent = sum of TOTAL_PRICE. Average deal = total spent / total purchases.
- **Repeat buyer flag:** If total purchases > 1, displays "REPEAT BUYER" status; otherwise "FIRST-TIME BUYER".
- **Year/make/model display:** Concatenated into a 17-character display field (4-digit year + space + 3-char make + space + 6-char model).
- **Trade-in:** Shows trade allowance amount if present (nullable column).

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- DCLCUSTM — DCLGEN for CUSTOMER table
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLVEHCL — DCLGEN for VEHICLE table
- DCLTRDEIN — DCLGEN for TRADE_IN table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates customer ID is provided and numeric. Handles customer not found. Gracefully handles case where customer has no purchase history.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** GET /api/customers/{id}/history
- **React Page:** CustomerHistory
- **Key Considerations:** The 10-deal limit should become paginated. The repeat buyer status is a derived attribute that could be stored or computed at query time. The summary statistics should be part of the response payload. The SALES_DEAL + VEHICLE join pattern is a common query that should be optimized with proper indexing and potentially a view. The deal status filter (CL/DL/AP) defines the "completed deal" business concept.
