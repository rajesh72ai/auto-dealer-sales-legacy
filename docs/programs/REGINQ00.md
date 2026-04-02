# REGINQ00 — Registration Inquiry

## Overview
- **Program ID:** REGINQ00
- **Module:** REG — Registration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** RGIN
- **Source:** cbl/online/reg/REGINQ00.cbl
- **Lines of Code:** 510
- **Complexity:** Medium

## Purpose
Inquires on vehicle registration status by registration ID, VIN, deal number, or customer ID. Joins Registration, Vehicle, Customer, and Sales_Deal tables to display full registration details including plate number, title number, fees, and status. Supports PF7/PF8 cursor-based pagination when multiple registrations match.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASRGIN00
- **Message Format:** Input: reg ID, deal number, VIN, customer ID, page action (F/B/blank). Output: registration details, vehicle description, customer name, plate, title, fees, status, page info.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.REGISTRATION | SELECT (cursor) | Retrieve registration records matching search criteria |
| AUTOSALE.VEHICLE | JOIN | Get vehicle description (year, make, model) |
| AUTOSALE.CUSTOMER | JOIN | Get customer name (Last, First) |
| AUTOSALE.SALES_DEAL | JOIN | Join for deal linkage |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- At least one search key (reg ID, deal number, VIN, or customer ID) is required.
- Uses a scrollable cursor (CSR_REG_INQ) with dynamic WHERE clause using OR-based optional parameters.
- Supports pagination: PF7 decrements page, PF8 increments page. Skips rows for paging.
- Formats registration type descriptions (NW=NEW, TF=TRANSFER, RN=RENEWAL, DP=DUPLICATE).
- Formats status descriptions (PR=PREPARING, VL=VALIDATED, SB=SUBMITTED, PG=PROCESSING, IS=ISSUED, RJ=REJECTED, ER=ERROR).
- Handles nullable columns (plate, title, lien holder, dates) with null indicators.
- Computes total fees (reg fee + title fee) for display.
- Results ordered by CREATED_TS DESC (most recent first).

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- IMS GU failure produces error message.
- DB2 cursor errors invoke COMDBEL0 and set error message.
- SQLCODE +100 during fetch sets end-of-data flag.
- "NO REGISTRATION RECORDS FOUND" when no rows match criteria.

## Modernization Notes
- **Target Module:** registration
- **Target Endpoint:** GET /api/registrations?regId=&vin=&dealNumber=&customerId=
- **React Page:** RegistrationTracker
- **Key Considerations:** Pagination currently uses cursor skip approach; replace with OFFSET/LIMIT or keyset pagination. The multi-key OR-based search should be implemented as query parameters on a REST endpoint. Nullable column handling becomes standard JSON null.
