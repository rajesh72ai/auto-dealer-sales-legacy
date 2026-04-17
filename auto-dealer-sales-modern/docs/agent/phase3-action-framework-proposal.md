# AI Agent — Phase 3 Proposal: Safe Action Framework

**Status:** Proposal · Drafted 2026-04-16 · Not yet approved for build
**Predecessor:** Phase 2 (UX polish + skill enrichment, shipped 2026-04-15)
**Goal:** Move the Agent from ~95% read-only to a trusted action executor, with per-mutation confirmation and audit trail.

---

## 1. Motivation

### What the Agent does today (post Phase 2)
Query, analysis, reasoning. Chains 4–8 tool calls per workflow. Applies domain rules (aging thresholds, APR-by-credit-tier, warranty escalation windows). Surfaces non-obvious insights (referral chains, stalled deals, loyalty candidates).

### What it does NOT do
Real work. Only two mutation tools are exposed in the skill:
- `create_lead` — adds a prospect
- `run_credit_check` — external side effect + audit

Deals, finance applications, inventory moves, batch triggers, registrations, warranty claims — all read-only from the agent, even though the underlying REST APIs fully support writes.

### Why the gap
Not a capability limit — a deliberate safety stance. The foundations needed for safe writes don't exist yet:

1. No dry-run preview — user can't see impact before commit
2. No confirmation UX — agent would act without explicit "yes"
3. No agent-specific audit trail — tool calls are invisible (OpenClaw shim hides them)
4. No rollback / compensating actions — mid-chain errors leave partial state
5. No per-action approval policy — all roles see the same write scope
6. No write allow-list in skill — agent could invent unsafe DELETEs

Tracked historically as Tier 2 item #5 in `project_real_agent_gaps.md`.

---

## 2. Use cases to unlock

### Tier A — Sales floor ergonomics (highest daily-use leverage)

| # | Utterance | Writes | Current UX cost |
|---|---|---|---|
| A1 | "Start a deal for customer 7 on VIN xyz" | SalesDeal (WS), DealLineItem, IncentiveApplied, StockPosition reservation | 4–5 screens, manual pricing lookup |
| A2 | "Book the trade-in — 2019 Civic, 45K miles, VIN xyz, $12,000 allowance" | TradeIn, recalc deal totals, lien follow-up flag | Separate modal, manual totals |
| A3 | "Submit finance app for deal DL01000001 to Ally at 6.9% / 60 months" | FinanceApp, APR band validation, submission record | Separate finance module, credit re-lookup |
| A4 | "Apply the March loyalty incentive to deal DL01000001" | IncentiveApplied, eligibility check, profitability recalc | Manual eligibility verification |

### Tier B — Manager workflows (medium volume, high judgment)

| # | Utterance | Writes | Role gate |
|---|---|---|---|
| B1 | "Approve deal DL01000001" | SalesApproval, WS→AP transition | MANAGER |
| B2 | "Transfer VIN xyz from DLR01 to DLR03" | StockTransfer, StockPosition (both sides), snapshot | MANAGER |
| B3 | "Mark VIN xyz arrived and ready for PDI" | Shipment status, StockPosition, PDI schedule | MANAGER / OPERATIONS |
| B4 | "Close warranty claim WC2026-0042 with $850 approved" | WarrantyClaim status, payment, exposure update | MANAGER / FINANCE |

### Tier C — Operator / batch workflows (dangerous; needs explicit approval UI)

| # | Utterance | Risk |
|---|---|---|
| C1 | "Run nightly commission batch for March 2026" | Mass financial writes; reversal is manual |
| C2 | "Archive registrations older than 3 years for DLR01" | Purge — hard to undo |
| C3 | "Send recall notices for campaign REC-2026-01 to all affected VINs" | Customer-visible side effect |

### Tier D — Cross-system orchestration (where the agent earns its keep)

| # | Utterance | Why it shines |
|---|---|---|
| D1 | "Customer 42 just came in — pull 360, run fresh credit if stale, then start a deal on whatever vehicle I point to next" | Query → conditional write → interactive follow-up |
| D2 | "For every aging vehicle past 60 days at DLR01, propose a transfer recommendation and on my OK execute" | Batch reasoning + batch action with per-item confirmation |
| D3 | "Morning triage: identify stalled deals; for each, nudge salesperson (create task) or escalate to manager (create flag)" | Proactive monitoring + small writes |

---

## 3. Architecture — Safe Action Framework

### 3.1 Core contract

Every mutation follows a **three-step protocol**:

```
1. PROPOSE   — agent calls endpoint with ?dryRun=true, receives impact preview
2. CONFIRM   — widget renders inline Execute/Cancel card with the preview
3. COMMIT    — on user approval, agent re-calls without dryRun; audit row written
```

The agent cannot skip PROPOSE → CONFIRM → COMMIT. The skill enforces this as a hard rule; the backend enforces it structurally by requiring a fresh `X-Confirmation-Token` from the widget.

### 3.2 Backend components

```
src/main/java/com/autosales/modules/agent/action/
├── ActionController.java                   POST /api/agent/actions/propose
│                                           POST /api/agent/actions/confirm/{token}
├── ActionService.java                      orchestrates dry-run + commit
├── ActionRegistry.java                     allow-list of (tool, endpoint, roles, dry-run support)
├── ConfirmationTokenService.java           short-lived (5 min) token bound to user + payload hash
├── AgentToolCallAuditService.java          per-call audit row
├── dryrun/
│   ├── DryRunExecutor.java                 intercepts calls, runs in same transaction, rolls back
│   └── ImpactPreview.java                  structured diff (rowsAdded, rowsChanged, rollupsAffected)
├── entity/
│   ├── AgentToolCallAudit.java             input, output, timestamp, user, approved/rejected, elapsed
│   └── AgentActionProposal.java            token, tool, payload, previewJson, expiresAt, status
└── repository/
    ├── AgentToolCallAuditRepository.java
    └── AgentActionProposalRepository.java
```

### 3.3 Database changes (V45, V46)

```sql
-- V45__create_agent_tool_call_audit.sql
CREATE TABLE agent_tool_call_audit (
    id            BIGSERIAL PRIMARY KEY,
    user_id       VARCHAR(20)  NOT NULL,
    conversation_id UUID,
    tool_name     VARCHAR(64)  NOT NULL,
    endpoint      VARCHAR(200) NOT NULL,
    method        VARCHAR(10)  NOT NULL,
    payload_json  TEXT,
    response_json TEXT,
    status        VARCHAR(20)  NOT NULL,    -- PROPOSED / CONFIRMED / REJECTED / EXECUTED / FAILED
    http_status   INTEGER,
    elapsed_ms    INTEGER,
    created_at    TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT fk_audit_conv FOREIGN KEY (conversation_id)
        REFERENCES agent_conversation(id) ON DELETE SET NULL
);
CREATE INDEX idx_audit_user_date ON agent_tool_call_audit(user_id, created_at DESC);
CREATE INDEX idx_audit_tool      ON agent_tool_call_audit(tool_name, created_at DESC);

-- V46__create_agent_action_proposal.sql
CREATE TABLE agent_action_proposal (
    token         UUID PRIMARY KEY,
    user_id       VARCHAR(20)  NOT NULL,
    conversation_id UUID,
    tool_name     VARCHAR(64)  NOT NULL,
    payload_json  TEXT         NOT NULL,
    preview_json  TEXT         NOT NULL,
    status        VARCHAR(20)  NOT NULL,    -- PENDING / CONFIRMED / REJECTED / EXPIRED
    expires_at    TIMESTAMP    NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT now(),
    decided_at    TIMESTAMP
);
CREATE INDEX idx_proposal_user_pending ON agent_action_proposal(user_id, status) WHERE status = 'PENDING';
```

### 3.4 Skill changes (SKILL.full.md)

Add a top-level section:

```
## Write-tool protocol (MANDATORY)

All mutations MUST follow the three-step protocol:

1. State intent in prose ("I'll create a deal for customer 7 on VIN xyz")
2. Call POST /api/agent/actions/propose with the write intent → receive token + preview
3. Relay the preview to the user, ask "Execute? (yes/no)"
4. Wait for user confirmation in the next turn — do NOT assume yes
5. On yes: call POST /api/agent/actions/confirm/{token}
6. On no: call DELETE /api/agent/actions/reject/{token}

NEVER call the raw write endpoints directly. NEVER chain multiple writes without
per-item confirmation. If any step fails, STOP and report — do not improvise
compensating actions.

## Write-tool allow-list (the only mutations you may propose)

TIER A: create_deal, add_trade_in, submit_finance_app, apply_incentive
TIER B: approve_deal, transfer_stock, mark_arrived, close_warranty_claim
TIER C: run_batch_job, archive_registrations, send_recall_notices
TIER D: (composite — chains of the above, still one confirmation per write)

Each tool names its role gate. Respect `{userRole}` injected via system prompt.
Refuse gracefully if the user lacks the role.
```

### 3.5 Frontend changes (AgentWidget.tsx)

When the agent emits a proposal, render an inline confirmation card:

```
┌─────────────────────────────────────────────────┐
│ ⚠ Proposed Action                               │
│ Tool: create_deal                               │
│                                                 │
│ Impact preview:                                 │
│   + 1 SalesDeal (DL01000042, status=WS)         │
│   + 3 DealLineItems (price, freight, tax)       │
│   + 1 IncentiveApplied (LOYALTY-MAR2026)        │
│   ↻ StockPosition VIN xyz: AVAILABLE→RESERVED   │
│   Δ Deal front gross: $2,840                    │
│                                                 │
│   [ Execute ]   [ Cancel ]   ⏱ expires in 4:52  │
└─────────────────────────────────────────────────┘
```

- Confirmation card is part of the assistant message bubble (not modal)
- Execute fires `POST /api/agent/actions/confirm/{token}`
- Cancel fires `DELETE /api/agent/actions/reject/{token}`
- Token expiry: 5 minutes; expired proposals require the agent to re-propose
- Widget remembers decision — card is replaced with a compact "✓ Executed" or "✗ Cancelled" row

### 3.6 Role-aware skill prompt

The existing `AgentService` system prompt must gain:

```java
String rolePrompt = "Current user: " + user.getUserId() +
                    " · Role: " + user.getRole().name() +
                    " · Dealer: " + user.getDealerCode();
```

Skill consults `{userRole}` placeholder to decide whether to offer Tier B actions. MANAGER-only tools refuse politely for SALESPERSON.

### 3.7 Dry-run implementation strategies

Two paths, used per-endpoint:

**A. Transactional rollback (preferred for most writes)**
```java
@Transactional
public ImpactPreview propose(CreateDealRequest req) {
    var deal = dealService.createDeal(req);     // real write
    var preview = previewBuilder.from(deal);    // capture state
    throw new DryRunRollback(preview);           // rollback via exception
}
```
Downside: fires @Auditable, sequences advance. Acceptable for a dry-run.

**B. Simulated preview (for side-effect endpoints — batch, notifications)**
Dedicated `previewX()` method in the service that computes the impact without touching DB. Required for any endpoint with external side effects (emails, payments, file writes).

Registry marks each tool as `TRANSACTIONAL_DRYRUN` or `SIMULATED_DRYRUN`.

### 3.8 Compensating actions (Tier D only)

For chained mutations, maintain a compensation log per confirmation token:

```java
record CompensationStep(String tool, Map<String,Object> inverseArgs);
List<CompensationStep> chainLog;
```

If step N fails, run steps N-1 → 0 in reverse. Document the inverse for every Tier A/B write in the registry. Tier C has no inverse — those failures stop, alert, and require manual cleanup.

---

## 4. Rollout plan — 5 stages

### Stage 1 — Foundation (no user-visible behavior yet)
**Deliverable:** plumbing that doesn't yet execute writes.

- V45 + V46 migrations
- `ActionRegistry`, `ConfirmationTokenService`, `AgentToolCallAuditService`, entities
- `POST /api/agent/actions/propose` endpoint returning stub previews
- Unit tests: 8–10 tests on token lifecycle, registry allow-list, audit writes
- No skill changes yet; no UI changes yet

### Stage 2 — First real action (create_lead uplift + create_deal)
**Deliverable:** one Tier A write with full protocol.

- Implement `create_deal` proposal → preview → confirm flow end-to-end
- Migrate existing `create_lead` to the same protocol (retire the direct skill tool)
- Skill changes: add MANDATORY protocol section, allow-list with just these two tools
- AgentWidget: inline confirmation card UI
- Smoke test: "Start a deal for customer 7 on VIN …" end-to-end

### Stage 3 — Tier A completion
**Deliverable:** all four sales-floor utterances working.

- Add `add_trade_in`, `submit_finance_app`, `apply_incentive`
- Per-tool preview builders
- Expand test coverage to all four tools

### Stage 4 — Tier B with role gates
**Deliverable:** manager-only actions.

- Role injection into system prompt
- MANAGER-only registry entries: `approve_deal`, `transfer_stock`, `mark_arrived`, `close_warranty_claim`
- Refusal tests: salesperson attempting manager action gets graceful decline

### Stage 5 — Tier C (dangerous) + Tier D (chained)
**Deliverable:** batch triggers with extra-strict confirmation + compensation log for chains.

- Tier C gets a "double confirmation" (type the action name to confirm)
- Compensation log + rollback on chain failure
- Observability: `/api/agent/actions/history` admin page

---

## 5. Testing strategy

- **Unit:** per-tool registry, token expiry, dry-run rollback, audit writes (~25 tests)
- **Integration:** propose → confirm full flow with real DB (~12 tests across Tiers)
- **Chaos:** force chain-step-3 to fail, verify steps 1–2 compensate
- **Negative:** stale token, wrong user token, expired token, replay attack
- **Skill fidelity:** manual tests that Claude never calls raw write endpoints without proposing first (prompt-level enforcement)

---

## 6. Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Claude bypasses protocol and calls raw writes | Medium | Backend rejects any write without `X-Confirmation-Token`. Skill rule is belt-and-suspenders |
| Dry-run rollback triggers @Auditable noise | High | Filter rollback-exception stack in AuditAspect; add `dryRun=true` flag to audit rows |
| Sequences advance during dry-run | Low | Accept it — dealer codes aren't sequence-driven; numeric gaps are tolerable |
| User approves wrong action (fat-finger) | Medium | 5-min token expiry + show full preview + Tier C requires typing the action name |
| OpenClaw tool-call invisibility obscures writes | Medium | Our audit table is the source of truth. Agent audit UI surfaces it per conversation |
| Role escalation via prompt injection | Medium | Backend re-validates role from JWT on every confirm; skill role text is informational only |
| Chain fails mid-way leaving partial state | Medium | Compensation log; Tier C has no chain — single-action only |

---

## 7. Open decisions (need user input before build)

1. **Dry-run strategy default** — transactional-rollback (A) vs. simulated (B)? Recommend A as default, B only where A is unsafe.
2. **Confirmation scope** — per-action (user confirms each write in a chain) vs. per-plan (user confirms the whole chain upfront)? Recommend **per-action** for safety, even though it's more clicks.
3. **Tier C gate** — require typed action name, or just an extra "Really execute?" click? Recommend **typed name** for batches + purges.
4. **Token delivery** — stream as a structured SSE event (`event: proposal`) or embed as a JSON code block in the message? Recommend **structured SSE event** so the widget can render confirmation UI without parsing prose.
5. **Mobile-style undo window** — after executed, show "Undo (10s)" for reversible Tier A/B? Nice-to-have, skip for v1.
6. **Scope of v1** — Stage 1+2+3 (Tier A only) as the MVP, or push through to Tier B? Recommend **Tier A as v1**, Tier B as v2.

---

## 8. Out of scope (will remain so)

- Tool-call trace visibility through OpenClaw — already probed and rejected (`feedback_openclaw_tool_visibility.md`). The agent's own prose + our audit table cover the gap.
- Real Anthropic token counts — still stubbed to 0 by OpenClaw; char-based estimation remains.
- Portfolio-wide reuse of the action framework — AutoSales only for now; reuse story is a separate initiative.
- Multi-modal (image upload) — independent track.
- Fine-tuned specialist models — long-term only.

---

## 9. Summary for approval

**What we're proposing:** a Safe Action Framework that lets the agent do real work (create deals, submit finance apps, approve, transfer, trigger batches) with mandatory propose → confirm → commit per mutation, full audit trail, and role gates.

**Effort estimate:**
- Stage 1: ~1 session (plumbing)
- Stage 2: ~1 session (first real action + UI)
- Stage 3: ~1 session (rest of Tier A)
- Stage 4: ~1 session (Tier B)
- Stage 5: ~1 session (Tier C + chains)
- **Total: ~5 focused sessions** to full Tier A+B+C coverage.

**Recommended v1 (fastest to value):** Stages 1+2+3 → Tier A only. Ships four sales-floor writes that cover ~70% of daily salesperson keystrokes.

**Blocker for going live:** user approval on the six open decisions in §7.
