# VEHLST00 — Vehicle Inventory Listing

## Overview
- **Program ID:** VEHLST00
- **Module:** VEH — Vehicle Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** VHLS
- **Source:** cbl/online/veh/VEHLST00.cbl
- **Lines of Code:** 596
- **Complexity:** Medium

## Purpose
Scrollable list of vehicles with filters. Input: dealer code (required), optional model year, make, model, status, color. Displays 12 vehicles per page: VIN, stock number, year, model, color, status, days, location. PF7/PF8 paging. Shows count: "SHOWING 1-12 OF 47".

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (via WSMSGFMT)
- **MFS Output (MOD):** (via WSMSGFMT)
- **Message Format:** Input: function (SR=Search/NX=Next/PV=Previous), dealer code, model year, make, model, status, color. Output: filter description, up to 12 detail lines, "showing X-Y of Z", PF key labels.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.VEHICLE | SELECT (cursor CSR_VEH_LIST) | Fetch filtered vehicle list |
| AUTOSALE.VEHICLE | SELECT (cursor CSR_VEH_COUNT) | Count total matching vehicles |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format display fields |
| COMMSGL0 | Message formatting |

### Key Business Logic
- Dealer code required. All other filters are optional.
- Three functions: SR (Search/default), NX (Next Page), PV (Previous Page).
- Uses two cursors: one for count, one for data fetch.
- Pagination: 12 rows per page, cursor-skip approach (fetches and discards rows to reach offset).
- Page number tracked and passed through input on NX/PV.
- Filter description built dynamically from provided filters.
- Results ordered by DAYS_IN_STOCK DESC, then VIN.
- Handles nullable stock number and lot location with null indicators.
- Filter parameters use OR-based optional pattern (value or blank = all).

### Copybooks Used
- WSSQLCA
- WSIOPCB
- WSMSGFMT

### Error Handling
- Dealer code blank returns error.
- DB2 cursor errors return error messages.
- "NO VEHICLES FOUND MATCHING CRITERIA" if count is zero.
- "NO MORE VEHICLES ON THIS PAGE" if paged past end.

## Modernization Notes
- **Target Module:** vehicle
- **Target Endpoint:** GET /api/vehicles?dealerCode=&year=&make=&model=&status=&color=&page=&size=12
- **React Page:** VehicleSearch
- **Key Considerations:** The cursor-skip pagination is inefficient; replace with OFFSET/LIMIT or keyset pagination. The filter description is a UI concern. The "showing X of Y" pattern maps directly to paginated API responses with total count.
