# ADMDLR00 — Dealer Master Maintenance

## Overview
- **Program ID:** ADMDLR00
- **Module:** ADM — Administration
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** ADMD
- **Source:** cbl/online/adm/ADMDLR00.cbl
- **Lines of Code:** 978
- **Complexity:** High

## Purpose
Provides full CRUD operations on the DEALER table for managing dealer profiles. Supports inquiry by dealer code, adding new dealers, updating existing dealer information, and listing dealers by region code (up to 15 per screen). Validates address fields, state codes, phone numbers, and formats phone/fax via a common formatting module.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSADLR0 (Dealer Maintenance Screen)
- **MFS Output (MOD):** ASDLRI00 (Dealer Inquiry Response)
- **Message Format:** Input includes function (INQ/ADD/UPD/LST), dealer code (5), name (60), full address fields, phone (10 digits), fax, principal name, region (3), zone (2), OEM number, floor plan lender ID, max inventory, active flag, open date, user ID. Output includes formatted phone numbers (14 chars), all dealer fields, and status messages.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.DEALER | SELECT | Inquiry by dealer code |
| AUTOSALE.DEALER | INSERT | Add new dealer record |
| AUTOSALE.DEALER | UPDATE | Update existing dealer |
| AUTOSALE.DEALER | SELECT (cursor) | List dealers by region (max 15) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format phone and fax numbers from 10-digit to display format |
| COMLGEL0 | Audit logging for add/update operations |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Validation rules:** Dealer code, name, address line 1, city, state (must be 2 alpha characters validated via INSPECT/TALLYING), ZIP, phone (must be 10 numeric digits), region, and zone are all required. Max inventory must be numeric if provided.
- **Nullable fields:** ADDRESS_LINE2, FAX_NUMBER, and FLOOR_PLAN_LENDER_ID support null indicators.
- **Phone formatting:** Phone and fax are stored as 10-digit numbers and formatted for display via COMFMTL0 call.
- **Default values:** If active flag is blank, defaults to 'Y'. If max inventory is not numeric, defaults to 100.
- **Duplicate detection:** INSERT catches SQLCODE -803 (duplicate key) and returns a specific error message.
- **List by region:** Uses cursor DEALER_LIST_CSR ordered by dealer name, fetches max 15 rows.

### Copybooks Used
- WSIOPCB — IMS I/O PCB and function codes
- WSSQLCA — DB2 SQLCA
- DCLDEALR — DCLGEN for DEALER table

### Error Handling
Standard SQLCODE evaluation pattern: 0 = success, +100 = not found, -803 = duplicate, other = COMDBEL0 call. IMS GU failure detected via IO-STATUS-CODE. All errors route through 8000-SEND-ERROR paragraph with descriptive messages.

## Modernization Notes
- **Target Module:** admin
- **Target Endpoint:** GET /api/dealers/{code}, POST /api/dealers, PUT /api/dealers/{code}, GET /api/dealers?region={code}
- **React Page:** DealerManagement
- **Key Considerations:** The 15-dealer list limit should become a paginated endpoint. Phone formatting should move to the frontend. State code validation (using INSPECT/TALLYING for alpha characters) should use a proper state code enum. The 4100-POPULATE-DCLGEN section that maps input to DCLGEN fields maps directly to a DTO/entity mapper in the modern layer.
