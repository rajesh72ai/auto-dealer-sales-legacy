# CUSLEAD0 — Lead Tracking & Management

## Overview
- **Program ID:** CUSLEAD0
- **Module:** CUS — Customer Management
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** CSLD
- **Source:** cbl/online/cus/CUSLEAD0.cbl
- **Lines of Code:** 855
- **Complexity:** High

## Purpose
Manages customer leads through their full lifecycle from creation to conversion or loss. Supports adding leads, updating lead status, and listing leads by salesperson and/or status with overdue follow-up alerts. Implements a defined status lifecycle and links won leads to deal creation.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** Standard IMS input via WSMSGFMT
- **MFS Output (MOD):** Lead Management screen
- **Message Format:** Input includes function (AD=add, UP=update, LS=list), lead ID, customer ID, dealer code, source (3), interest model (6), interest year (4), status (2), assigned salesperson (8), follow-up date, notes (200), filter salesperson, filter status. Output has two modes: add/update confirmation shows lead ID, customer name, interest vehicle, follow-up date, salesperson, source, contact count. List mode shows up to 10 leads with ID, customer name, status, salesperson, follow-up date, contact count, overdue flag, plus total overdue count.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.CUSTOMER_LEAD | INSERT | Create new lead record |
| AUTOSALE.CUSTOMER_LEAD | SELECT + UPDATE | Update lead status and details |
| AUTOSALE.CUSTOMER_LEAD | SELECT (cursor) | List leads filtered by dealer, salesperson, and/or status |
| AUTOSALE.CUSTOMER | SELECT | Fetch customer name for display |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging for lead status changes |
| COMDBEL0 | DB2 error handling |
| COMDTEL0 | Date utilities for follow-up date calculations |

### Key Business Logic
- **Lead status lifecycle:** NW (New) -> CT (Contacted) -> AP (Appointment) -> TS (Test Drive) -> QT (Quote) -> WN (Won) / LS (Lost) / DD (Dead). Status transitions are validated.
- **Overdue detection:** Compares follow-up date against current date. If follow-up date < current date and lead is still active (not WN/LS/DD), marks as overdue with "YES" flag in list.
- **Overdue count:** Tallies total overdue leads and displays at bottom of list.
- **Won leads:** When status changes to WN, displays message "LEAD WON - USE TRANSACTION SLNW TO CREATE DEAL" linking to the sales deal creation process.
- **List filtering:** Cursor CSR_LEADS_ALL filters by dealer code (required), with optional salesperson and status filters. Treats blank filter values as "all" using OR condition.
- **Contact count:** Tracks number of contacts/interactions per lead.
- **Nullable fields:** Interest model, interest year, follow-up date, last contact date, and notes support null indicators.

### Copybooks Used
- WSSQLCA — DB2 SQLCA
- WSIOPCB — IMS I/O PCB
- WSMSGFMT — MFS message format areas
- WSAUDIT — Audit logging fields
- DCLCSLEAD — DCLGEN for CUSTOMER_LEAD table
- DCLCUSTM — DCLGEN for CUSTOMER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates lead ID exists for updates, customer ID exists for adds. Status transition validation prevents invalid state changes. DB errors via COMDBEL0.

## Modernization Notes
- **Target Module:** customer
- **Target Endpoint:** POST /api/leads, PUT /api/leads/{id}, GET /api/leads?dealer={code}&salesperson={id}&status={st}, GET /api/leads/overdue
- **React Page:** LeadManagement, LeadDetail
- **Key Considerations:** The lead status lifecycle is a state machine that should be explicitly modeled with transition rules. The overdue detection logic should become a scheduled background job or computed field. The "Won -> Create Deal" link represents a cross-module workflow that should be handled via event-driven architecture or a workflow engine. The list filtering with optional parameters maps naturally to query parameters on a GET endpoint.
