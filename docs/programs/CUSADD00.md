# CUSADD00 — Customer Add / Create Profile

## Overview
- **Program ID:** CUSADD00
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSAD
- **Source:** cbl/online/cus/CUSADD00.cbl
- **Lines of Code:** 1003
- **Complexity:** High

## Purpose
Creates new customer records in the CUSTOMER table. Validates all required fields including state code (against a 52-entry state table), ZIP format, phone format (10 digits), and email format (checks for @ sign and dot). Performs duplicate detection by matching last name + phone or last name + address, with a force-add (FA) function to override. Assigns a salesperson via round-robin from SYSTEM_USER if not provided.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input message via WSMSGFMT
- **MFS Output (MOD):** Customer Add Confirmation screen
- **Message Format:** Input includes function (AD/FA), dealer code, first/last name, middle initial, DOB, SSN last 4, driver license number/state, full address, home/cell phone, email (60), employer (40), income (11), customer type, source code, assigned salesperson. Output shows confirmation with customer ID, formatted name, address, phone numbers, salesperson, type, and source. Duplicate warning section shows matching customer details.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER | INSERT | Create new customer record |
| AUTOSALE.CUSTOMER | SELECT | Duplicate detection by last name + phone or address |
| AUTOSALE.SYSTEM_USER | SELECT (cursor) | Round-robin salesperson assignment |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Format phone numbers and names |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- **Duplicate detection:** Checks for existing customer with same last name + phone number, or same last name + address line 1. If duplicate found and function is AD (not FA), shows warning with duplicate customer details and instructs user to use FA to force-add.
- **Force-add:** Function code FA bypasses duplicate check and proceeds with insert.
- **State validation:** 52-entry table covering all US states plus DC and PR. State code must match one entry.
- **ZIP validation:** First 5 characters must be numeric digits.
- **Phone validation:** Must be exactly 10 numeric digits.
- **Email validation:** Checks for presence of @ sign and at least one dot after the @ sign.
- **Round-robin salesperson:** If no salesperson assigned, queries SYSTEM_USER for active salespeople at the dealer and assigns via round-robin cursor.
- **Nullable fields:** Middle initial, DOB, SSN last 4, driver license, address line 2, home phone, cell phone, email, employer, income, source, assigned salesperson all support null indicators.
- **Auto-generated ID:** Customer ID is auto-generated (likely via sequence).

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- WSAUDIT — Audit logging fields
- DCLCUSTM — DCLGEN for CUSTOMER table
- DCLSYUSR — DCLGEN for SYSTEM_USER table

### Error Handling
Uses WS-RETURN-CODE pattern (+0 = success, +8 = validation error, +16 = system error). DB errors handled via WS-DBERR-REQUEST/RESULT structure calling COMDBEL0. SQLCODE -803 caught for duplicate key on insert.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** POST /api/customers
- **React Page:** CustomerAdd
- **Key Considerations:** The duplicate detection logic is a critical business workflow that should be preserved as a pre-check API (POST /api/customers/check-duplicate). The force-add pattern maps to a query parameter or request flag. The round-robin salesperson assignment should become a service-layer algorithm. Email/phone/ZIP validation should use standard regex patterns. The 52-state validation table should become a shared reference data service.
