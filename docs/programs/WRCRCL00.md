# WRCRCL00 — Recall Management Online

## Overview
- **Program ID:** WRCRCL00
- **Module:** WRC — Warranty & Recall
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** WRCR
- **Source:** cbl/online/wrc/WRCRCL00.cbl
- **Lines of Code:** 506
- **Complexity:** High

## Purpose
Online recall management with three functions: INQ (campaign detail), VEH (list affected vehicles), and UPD (update vehicle recall status). Supports status transitions: SC=Scheduled, IP=In-Progress, CM=Complete, NA=Not-Applicable. On completion, increments the campaign's TOTAL_COMPLETED count.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** (standard IMS input)
- **MFS Output (MOD):** ASWRCR00
- **Message Format:** Input: function (INQ/VEH/UPD), campaign ID, VIN (for UPD), new status, status filter (for VEH). Output: campaign details (ID, NHTSA number, description, severity, affected models, remedy, counts) or vehicle list (up to 10 affected vehicles with status).

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.RECALL_CAMPAIGN | SELECT | Read campaign details |
| AUTOSALE.RECALL_CAMPAIGN | UPDATE | Increment TOTAL_COMPLETED on completion |
| AUTOSALE.RECALL_VEHICLE | SELECT (cursor) | List affected vehicles with status filter |
| AUTOSALE.RECALL_VEHICLE | SELECT | Read current recall status for update |
| AUTOSALE.RECALL_VEHICLE | UPDATE | Apply new recall status |
| AUTOSALE.VEHICLE | JOIN | Get vehicle description |
| AUTOSALE.MODEL_MASTER | JOIN | Get model name |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit logging |
| COMDBEL0 | DB2 error handling |
| COMFMTL0 | Field formatting |

### Key Business Logic
- Campaign ID is required for all functions.
- **INQ:** Displays full campaign detail including NHTSA number, severity, affected models, remedy description, total affected, and total completed counts.
- **VEH:** Lists up to 10 affected vehicles with VIN, description, recall status, and scheduled date. Optional status filter.
- **UPD:** Updates vehicle recall status. Valid statuses: SC (Scheduled), IP (In-Progress), CM (Complete), NA (Not-Applicable). VIN required. On status change to CM (and not already CM), increments RECALL_CAMPAIGN.TOTAL_COMPLETED.
- Status update logged with old->new status via COMLGEL0.

### Copybooks Used
- WSSQLCA
- WSIOPCB

### Error Handling
- Campaign not found returns error.
- Vehicle not in recall campaign returns error.
- Invalid status code returns error.
- DB2 errors call COMDBEL0.

## Modernization Notes
- **Target Module:** registration (warranty/recall)
- **Target Endpoint:** GET /api/recalls/{campaignId}, GET /api/recalls/{campaignId}/vehicles, PUT /api/recalls/{campaignId}/vehicles/{vin}/status
- **React Page:** RegistrationTracker
- **Key Considerations:** The three-function pattern should become separate REST endpoints. The TOTAL_COMPLETED counter increment should be handled atomically or via a trigger. Status filter on vehicle list maps to query parameter.
