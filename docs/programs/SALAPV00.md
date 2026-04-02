# SALAPV00 — Sales Approval Workflow

## Overview
- **Program ID:** SALAPV00
- **Module:** SAL — Sales Process
- **Type:** Online (IMS DC)
- **IMS Transaction Code:** SALA
- **Source:** cbl/online/sal/SALAPV00.cbl
- **Lines of Code:** 561
- **Complexity:** High

## Purpose
Implements the sales approval workflow for deals pending manager authorization. Validates the approver has sufficient authority based on user type (M=Manager or above). Applies threshold-based auto-approval logic: deals below $500 front gross can be approved by any manager, while "loser deals" (below $0 gross) require General Manager authority. Creates a SALES_APPROVAL audit record and updates the deal status to AP (Approved) or back to NE (Negotiating) on rejection.

## Technical Details

### IMS DC Interface
- **MFS Input (MID):** MFSSLINP (Sales Input Screen)
- **MFS Output (MOD):** ASSLAP00 (Approval Response)
- **Message Format:** Input includes deal number (10), approver ID (8), action (AP=approve, RJ=reject), and comments (200). Output shows deal header with vehicle price and front/total gross, approver info with type and action taken, old/new status, approval threshold description, and comments.

### Database Access
| Table | Operation | Purpose |
|-------|-----------|---------|
| AUTOSALE.SALES_DEAL | SELECT | Read deal details including prices and gross |
| AUTOSALE.SALES_DEAL | UPDATE | Update deal status (AP on approve, NE on reject) |
| AUTOSALE.SALES_APPROVAL | INSERT | Create approval/rejection audit record |
| AUTOSALE.SYSTEM_USER | SELECT | Validate approver authority (user type) |

### Called Subroutines
| Program | Purpose |
|---------|---------|
| COMLGEL0 | Audit log entry for approval/rejection |
| COMDBEL0 | DB2 error handling |
| COMMSGL0 | Message builder for status messages |

### Key Business Logic
- **Authority validation:** Approver must have user type M (Manager) or higher. User type checked from SYSTEM_USER table.
- **Gross threshold rules:**
  - Front gross >= $500: Standard approval — any manager can approve.
  - Front gross $0-$500: Below threshold — requires manager, shown as "BELOW STANDARD MARGIN".
  - Front gross < $0 (loser deal): Requires GM (General Manager) authority.
- **Approval flow:** On AP action — inserts SALES_APPROVAL record, updates deal status from current to AP, advances deal to F&I stage.
- **Rejection flow:** On RJ action — inserts SALES_APPROVAL record with rejection comments, updates deal status back to NE for renegotiation.
- **Status tracking:** Captures and displays old status and new status for audit trail.

### Copybooks Used
- WSIOPCB — IMS I/O PCB
- WSSQLCA — DB2 SQLCA
- WSMSGFMT — MFS message format areas
- DCLSLDEL — DCLGEN for SALES_DEAL table
- DCLSLAPV — DCLGEN for SALES_APPROVAL table
- DCLSYUSR — DCLGEN for SYSTEM_USER table

### Error Handling
Uses WS-RETURN-CODE pattern. Validates deal exists, is in correct status for approval, and approver has authority. DB errors via standard COMDBEL0 pattern. Invalid action codes rejected with message.

## Modernization Notes
- **Target Module:** sales
- **Target Endpoint:** POST /api/deals/{dealNumber}/approve, POST /api/deals/{dealNumber}/reject
- **React Page:** DealApproval
- **Key Considerations:** The approval authority rules (manager vs. GM based on gross threshold) are critical business rules that should be externalized to a rules engine or configuration. The threshold ($500) is hardcoded and should be configurable per dealer. The approval/rejection pattern maps well to separate REST endpoints. The approval record (SALES_APPROVAL) is an audit/workflow table that should be preserved. Role-based access control should be enforced at the API gateway level.
