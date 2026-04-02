# CUSLST00 — Customer Listing / Browse

## Overview
- **Program ID:** CUSLST00
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSLS
- **Source:** cbl/online/cus/CUSLST00.cbl
- **Lines of Code:** 520
- **Complexity:** Medium

## Purpose
Provides a paginated browse view of all customers for a given dealer with configurable sort options. Displays 15 customers per page with PF7/PF8 paging. Shows total customer count and current sort order. Supports sorting by name, creation date, or customer type.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input via WSMSGFMT
- **MFS Output (MOD):** Customer Listing screen
- **Message Format:** Input includes function (LS=list, NX=next page, PV=prev page), dealer code (5), sort by (NM/DT/TY). Output shows dealer code, page number/total, column headers, up to 15 customer rows (ID, name, phone, type, source, created date), total customer count, sort description, and navigation instructions.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | SELECT (cursor CSR_CUST_BY_NAME) | List ordered by last name, first name |
| AUTOSALE.CUSTOMER | SELECT (cursor CSR_CUST_BY_DATE) | List ordered by created timestamp desc |
| AUTOSALE.CUSTOMER | SELECT (cursor CSR_CUST_BY_TYPE) | List ordered by customer type, then last name |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format phone numbers |
| COMMSGL0 | Message formatting |

### Key Business Logic
- **Sort options:** NM = by name (last, first), DT = by date (most recent first), TY = by type then name. Defaults to NM if not specified.
- **Three separate cursors:** One for each sort order, all filtering by DEALER_CODE and selecting the same columns: CUSTOMER_ID, FIRST_NAME, LAST_NAME, HOME_PHONE, CUSTOMER_TYPE, SOURCE_CODE, CREATED_TS.
- **Pagination:** 15 rows per page. Tracks page number and calculates total pages from total count. WS-ROWS-TO-SKIP computed for offset-based cursor positioning.
- **Dealer filter:** All cursors filter by dealer code (required input).
- **Created date display:** Extracts date portion from CREATED_TS (26-char timestamp) for display.
- **Navigation line:** Shows "PF7=PREV PAGE PF8=NEXT PAGE PF3=EXIT" at bottom.

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- DCLCUSTM — DCLGEN for CUSTOMER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates dealer code is required. Handles empty result set with "no customers found" message.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** GET /api/customers?dealer={code}&sort={name|date|type}&page={n}&size=15
- **React Page:** CustomerList
- **Key Considerations:** The three separate cursors for sort order should become a single query with dynamic ORDER BY or handled via the ORM/query builder. Pagination should use standard offset/limit or keyset pagination for better performance at scale. The 15-per-page limit is arbitrary and should be configurable. The dealer code filter should come from the authenticated user's context in the modern system.
