# WRCRPT00 — Warranty Claims Summary Report

## Overview
- **Program ID:** WRCRPT00
- **Module:** WRC — Warranty & Recall
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** WRRT
- **Source:** cbl/online/wrc/WRCRPT00.cbl
- **Lines of Code:** 545
- **Complexity:** Medium

## Purpose
Online summary report of warranty claims for a dealer. Accepts dealer code and optional date range, queries WARRANTY_CLAIM table, and returns totals by claim type with counts and dollar amounts. Includes approved/denied breakdowns, grand totals, and average claim amount.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASWRRT00
- **Message Format:** Input: dealer code (required), from date (optional), to date (optional). Output: dealer name, date range, up to 7 claim type summary lines (type, claims, labor, parts, total, approved, denied), grand totals, average claim amount.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.DEALER | SELECT | Validate dealer exists and is active |
| AUTOSALE.WARRANTY_CLAIM | SELECT (cursor) | Aggregate claims by type with optional date filter |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMFMTL0 | Currency formatting for grand total |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Dealer code is required. Dealer validated as active.
- Date range is optional: both dates provided uses range, from-date only uses from-date to current date, neither uses all dates.
- FROM date must be <= TO date.
- Cursor aggregates by CLAIM_TYPE using SUM and CASE expressions for approved (status AP/PA/PD) and denied (status DN) counts.
- 7 claim type descriptions: BA=BASIC, PT=POWERTRAIN, EX=EXTENDED, GW=GOODWILL, RC=RECALL, CM=CAMPAIGN, PD=PRE-DELIVERY.
- Per type: claim count, labor total, parts total, claim total, approved count, denied count.
- Grand totals accumulated across all types.
- Average claim = grand total / grand claims count.
- Grand total formatted via COMFMTL0 for display.
- Summary message includes total claims and formatted total amount.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Dealer not found or inactive returns error.
- Invalid date range (from > to) returns error.
- DB2 cursor errors call COMDBEL0.
- "NO WARRANTY CLAIMS FOUND" if no claims exist for criteria.

## Modernization Notes
- **Target Module:** registration (warranty analytics)
- **Target Endpoint:** GET /api/warranty/claims/summary?dealerCode=&fromDate=&toDate=
- **React Page:** RegistrationTracker
- **Key Considerations:** This is a read-only analytics report ideal for caching. The CASE-based approved/denied counting can be done in SQL or application layer. Date range filtering maps directly to query parameters. Consider adding export functionality (CSV/PDF) in the modernized system.
