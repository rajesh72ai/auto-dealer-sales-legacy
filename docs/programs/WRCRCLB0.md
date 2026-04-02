# WRCRCLB0 — Recall Batch (Manufacturer Feed)

## Overview
- **Program ID:** WRCRCLB0
- **Module:** WRC — Warranty & Recall
- **Type:** Online (IMS DC) — Batch Trigger
- **IMS Transaction Code:** WRRB
- **Source:** cbl/online/wrc/WRCRCLB0.cbl
- **Lines of Code:** 426
- **Complexity:** High

## Purpose
Processes inbound recall campaign feed from manufacturer. Inserts a RECALL_CAMPAIGN record, then for each VIN in the feed: validates VIN format via COMVALD0, checks if VIN exists in VEHICLE table, and inserts RECALL_VEHICLE with status OP (Open). Skips unmatched VINs with warning. Counts: total in feed, matched, unmatched, errors.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASWRRB00
- **Message Format:** Input: campaign header (ID, NHTSA number, description, severity, affected models, remedy) + VIN count + up to 50 VINs. Output: campaign ID, total in feed, matched count, unmatched count, error count.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.RECALL_CAMPAIGN | SELECT COUNT | Check if campaign already exists |
| AUTOSALE.RECALL_CAMPAIGN | INSERT | Create new recall campaign |
| AUTOSALE.VEHICLE | SELECT COUNT | Check if each VIN exists |
| AUTOSALE.RECALL_VEHICLE | INSERT | Create recall vehicle record with status 'OP' |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMVALD0 | VIN format validation |
| COMDBEL0 | DB2 error handling |
| COMLGEL0 | Audit logging of batch results |

### Key Business Logic
- Campaign ID and description are required. At least one VIN required.
- Duplicate campaign check: if campaign already exists, returns error.
- Campaign created with status 'AC' (Active), TOTAL_AFFECTED = VIN count, TOTAL_COMPLETED = 0.
- VIN processing loop (up to 50 VINs):
  - Blank VINs skipped (counted as unmatched).
  - VIN format validated via COMVALD0 ('VIN' function); invalid VINs counted as unmatched.
  - VIN existence checked against VEHICLE table; non-existent VINs counted as unmatched.
  - Matching VINs: RECALL_VEHICLE inserted with status 'OP' (Open).
  - Insert failures counted as errors.
- Batch results logged via COMLGEL0 with matched/unmatched/error counts.
- Final output message indicates success or "completed with errors".

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Campaign already exists returns error.
- Individual VIN failures (validation, not found, insert error) are counted but don't stop processing.
- DB2 errors on campaign insert call COMDBEL0 and stop processing.
- Batch log includes complete counts for troubleshooting.

## Modernization Notes
- **Target Module:** registration (warranty/recall)
- **Target Endpoint:** POST /api/recalls/campaigns (with VIN list in body)
- **React Page:** RegistrationTracker
- **Key Considerations:** This batch feed processing should become an async job or message queue consumer. The 50-VIN limit should be removed for bulk imports. Unmatched VINs should be reported in detail for follow-up. Consider manufacturer API integration rather than batch feed.
