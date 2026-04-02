# CUSUPD00 — Customer Update

## Overview
- **Program ID:** CUSUPD00
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSUP
- **Source:** cbl/online/cus/CUSUPD00.cbl
- **Lines of Code:** 782
- **Complexity:** High

## Purpose
Updates existing customer records with field-level change detection and comprehensive audit logging. Fetches the current record, compares each field to the input, and applies only changed fields. Validates all input (state code, ZIP, phone, email format). Displays a change summary showing old and new values for each modified field.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input via WSMSGFMT
- **MFS Output (MOD):** Customer Update Confirmation screen
- **Message Format:** Input includes function (UP), customer ID (9), and all customer fields (same as CUSADD00 — first/last name, middle init, DOB, SSN, driver license, address, phones, email, employer, income, type, source, salesperson). Output shows customer ID, name, change header, and up to 10 change detail lines each showing field name, old value, and new value. Displays total field count changed.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | SELECT | Fetch current record for comparison |
| AUTOSALE.CUSTOMER | UPDATE | Apply changed fields |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format phone numbers |
| COMLGEL0 | Audit logging with old and new values |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Fetch-compare-update pattern:** 1) Fetch current record into WS-OLD-RECORD, 2) Compare each input field against old value, 3) Build change summary (up to 10 changes), 4) Execute UPDATE with only changed fields, 5) Log audit with old/new values.
- **Field-level tracking:** Each changed field is recorded in a change line showing field name (15 chars), old value (30 chars), and new value (30 chars).
- **Same validations as CUSADD00:** State code (52-entry table), ZIP (first 5 digits numeric), phone (10 digits), email (@ sign and dot check).
- **Change count:** Tracks WS-CHANGE-COUNT; if zero, no update is performed and user is informed.
- **Nullable fields:** Same set as CUSADD00 — middle init, DOB, SSN last 4, driver license, address 2, home/cell phone, email, employer, income, source, assigned salesperson.
- **Audit trail:** Logs the complete set of old and new values for the changed fields via COMLGEL0.

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- WSAUDIT — Audit logging fields
- DCLCUSTM — DCLGEN for CUSTOMER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates customer ID exists. Handles customer not found (+100). DB errors via COMDBEL0. Validation errors return descriptive messages for each invalid field.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** PUT /api/customers/{id}
- **React Page:** CustomerEdit
- **Key Considerations:** The field-level change detection pattern is sophisticated and should be preserved in the audit logging. In a modern system, this could be implemented via JPA entity listeners or event sourcing. The change summary display maps to a response payload showing what was modified. The "no changes detected" check prevents unnecessary database writes and should be preserved. Optimistic locking should be added to prevent concurrent update conflicts.
