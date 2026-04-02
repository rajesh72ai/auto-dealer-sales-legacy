# CUSINQ00 — Customer Search / Inquiry

## Overview
- **Program ID:** CUSINQ00
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSIQ
- **Source:** cbl/online/cus/CUSINQ00.cbl
- **Lines of Code:** 901
- **Complexity:** High

## Purpose
Provides multi-criteria customer search with paginated results (10 per page) and full customer detail view. Supports search by last name (LIKE pattern), first name, phone (exact match on home or cell), driver license (exact), or customer ID. Results include paging via PF7/PF8 keys. Selecting from the list shows comprehensive customer detail.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input via WSMSGFMT
- **MFS Output (MOD):** Customer Search Results / Customer Detail screen
- **Message Format:** Input includes function (SR=search, SL=select, NX=next page, PV=prev page), search type (LN/FN/PH/DL/ID), search value (30), selection number (2), dealer code. Output has two modes: list mode shows page/total, column headers, up to 10 results (ID, name, phone, city/state, type, source), and total matching count. Detail mode shows full customer profile including address, phones, email, employer, income, driver license, SSN last 4, and assigned salesperson.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | SELECT (cursor CSR_CUST_LNAME) | Search by last name using LIKE pattern |
| AUTOSALE.CUSTOMER | SELECT (cursor CSR_CUST_PHONE) | Search by phone (home or cell, exact match) |
| AUTOSALE.CUSTOMER | SELECT (cursor CSR_CUST_DL) | Search by driver license number |
| AUTOSALE.CUSTOMER | SELECT | Detail view — full customer record by ID |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format phone numbers, SSN masking |
| COMMSGL0 | Message formatting for status/error messages |

### Key Business Logic
- **Search types:** LN = last name LIKE search (appends '%' for partial match); FN = first name; PH = phone exact match against both HOME_PHONE and CELL_PHONE; DL = driver license exact match; ID = customer ID direct lookup.
- **Pagination:** 10 results per page. Tracks page number and total pages. NX/PV functions handle page navigation. WS-ROWS-TO-SKIP calculated for offset-based paging.
- **Page cache:** Stores 10 customer IDs for the current page in WS-PAGE-CACHE for select operations.
- **Select from list:** SL function with a selection number (1-10) retrieves full detail for the selected customer from the page cache.
- **Detail view mode:** Switches output to detail layout showing all customer fields including nullable fields (address line 2, email, employer, income, SSN last 4, driver license, assigned salesperson).
- **Multiple cursors:** Three separate cursors defined for different search types, each returning the same column set but with different WHERE clauses and sort orders.

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- DCLCUSTM — DCLGEN for CUSTOMER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates search value is provided for each search type. Handles no results found gracefully. Detail mode handles customer not found.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** GET /api/customers?search={value}&type={LN|PH|DL|ID}&page={n}&size=10, GET /api/customers/{id}
- **React Page:** CustomerSearch, CustomerDetail
- **Key Considerations:** The multiple cursor pattern for different search types should become a single parameterized query with dynamic WHERE clause or separate repository methods. The pagination should use standard offset/limit or cursor-based paging. The select-from-list pattern is a UI concern that disappears in a web application (use direct links). The phone search matching both home and cell is an OR query that needs indexing attention. The SSN masking via COMFMTL0 should be handled at the API layer.
