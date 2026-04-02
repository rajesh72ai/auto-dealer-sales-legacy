# WRCNOTF0 — Warranty Recall Notification Generator

## Overview
- **Program ID:** WRCNOTF0
- **Module:** WRC — Warranty & Recall
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** WRNF
- **Source:** cbl/online/wrc/WRCNOTF0.cbl
- **Lines of Code:** 804
- **Complexity:** High

## Purpose
Generates recall notifications for affected vehicles. Given a recall campaign number: validates campaign exists and is active, finds all affected VINs, locates current owner for each VIN via latest delivered deal, retrieves customer contact info, checks if notification already exists, and inserts RECALL_NOTIFICATION records. Returns counts: created, already-notified, no-owner-found.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASWRNF00
- **Message Format:** Input: campaign number. Output: campaign number, notification counts (created, already-notified, no-owner), status message.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.RECALL_CAMPAIGN | SELECT | Validate campaign exists and is active |
| AUTOSALE.RECALL_VEHICLE | SELECT (cursor) | Find all affected VINs for campaign |
| AUTOSALE.SALES_DEAL | SELECT | Find current owner via latest delivered deal |
| AUTOSALE.CUSTOMER | SELECT | Get customer contact information |
| AUTOSALE.RECALL_NOTIFICATION | SELECT | Check if notification already exists |
| AUTOSALE.RECALL_NOTIFICATION | INSERT | Create new notification record |
| AUTOSALE.RECALL_CAMPAIGN | UPDATE | Update notification sent count |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMDTEL0 | Date calculation |
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |

### Key Business Logic
- Campaign number is required.
- Campaign must exist and be active.
- Iterates through all affected VINs in the campaign via cursor.
- For each VIN: looks up current owner through the most recent delivered SALES_DEAL, retrieves customer contact info, checks if a notification already exists for this campaign/VIN combination.
- If notification does not exist, inserts a new RECALL_NOTIFICATION record.
- Tracks three counts: notifications created, already-notified (skipped), and no-owner-found (skipped).
- Updates campaign with notification sent count.
- Logs batch processing results via COMLGEL0.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Campaign not found returns error.
- DB2 errors on cursor operations call COMDBEL0.
- Individual VIN processing errors are tracked in error count but do not stop batch.
- Insert failures for individual notifications logged via COMDBEL0.

## Modernization Notes
- **Target Module:** registration (warranty/recall)
- **Target Endpoint:** POST /api/recalls/{campaignId}/notifications
- **React Page:** RegistrationTracker
- **Key Considerations:** This is a batch-like operation that should be async in the modern system. Notifications could trigger email/SMS via a notification service. The owner lookup pattern (latest delivered deal) should be a shared service. Consider idempotency for re-running notification generation.
