# AUTOSALES Customer Demo Runbook
**Demo date:** 2026-05-11
**Frontend:** https://autosales-frontend-suxifos6uq-uc.a.run.app
**Backend:**  https://autosales-backend-suxifos6uq-uc.a.run.app
**Login:** `ADMIN001` / `Admin123` (dealer DLR01 = Lakewood Ford)
**Backup user:** `EVALUSER` / `Admin123` (also ADMIN, 1M-token quota — fallback if quota drains)

---

## 0. Pre-flight (do this 5 min before the demo)

1. **Open three browser tabs:**
   - Tab 1: the agent widget (Frontend URL → log in → open chat)
   - Tab 2: `<frontend>/admin/agent-trace` (the "glass-box" trace UI — secret weapon)
   - Tab 3: `<frontend>/admin/capability-gaps` (for the self-reporting-gap demo moment)
2. **Smoke-test one read prompt** so the model warms up and the first real demo prompt isn't a cold-start:
   - *"How many vehicles in my dealership?"* — should answer ~5-6 s
3. **Confirm V71 data landed** by asking *"Show me deals at DLR01 in the past week"* — expect 3 delivered deals (DL01000200-202) + 1 in CA + 1 in AP.

If the warm-up prompt is slow (>15 s) or errors, hit `<frontend>/api/agent` once via curl/Postman to wake the JVM; min-instances=1 should prevent cold-start, but a roll might have just happened.

---

## 1. Recommended demo flow (~25-30 min)

| Phase | Time | Goal | Prompts to use |
|---|---|---|---|
| **Open** | 2 min | Set framing: "AI-enable existing modern app on GCP" — show login | — |
| **Analyze** | 8 min | Show agent reasoning over live data (the chatbot story) | A1, A2, A5 |
| **Customer 360** | 3 min | Show entity lookup + single-token fix | A3 |
| **Anomaly hunt** | 4 min | Show agent finding things humans would miss | A6 |
| **Take real action** | 6 min | Show propose → confirm → audit (the governance story) | W1, W3, then W5 |
| **Glass-box close** | 3 min | Trace UI + capability-gap loop | A7 + Trace UI walkthrough |
| **Q&A** | rest | — | Have Hero prompts H1/H2 ready |

---

## 2. ANALYSIS / CHATBOT prompts (read-only, no propose card)

### A1 — Daily sales for the past week
Showcases **L11 fix** (today's date injected per turn) — the model can answer date-relative questions correctly.

| # | Prompt to type | What you'll see | Backed by |
|---|---|---|---|
| 1 | `Show me daily sales for DLR01 for the past week, and call out our best day.` | 3 deals in window (DL01000200 / 201 / 202), best day = 2026-05-08 by total_gross | V71 #2 |
| 2 | `How are our sales for this month so far at DLR01?` | Same 3 deals (May 1+), front gross totals | V71 #2 |
| 3 | `What was the total deal volume yesterday at DLR01?` | DL01000202 ($57,954) delivered 2026-05-10 | V71 #2 |

**Talking point:** *"The agent knows what 'past week' means right now. We inject today's date every turn — otherwise the model defaults to its training prior, which is anchored around 2024."*

---

### A2 — Inventory aging
Already proven in B1.2 smoke. Strong visual.

| # | Prompt | Expectation | Backed by |
|---|---|---|---|
| 1 | `Pull our inventory aging at DLR01. Highlight anything over 60 days, and tell me which 3 I should be most worried about.` | 2+ aged units flagged: F-150 (`1FTFW1E53NFA01571`, 203 days), Escape (`1FMCU9J93NUA01572`, 222 days), plus older V60/V61 stock | V71 #1 (aged) + V60/V61 |
| 2 | `Across all our dealers, what's the top 5 oldest unsold units?` | DLR03 Honda stock dominates (200-282 days) | V60/V61 |
| 3 | `How fresh is our F-150 inventory at DLR01?` | 3 fresh AV (<14 days) + 1 aged | V71 #1 |

**Talking point:** *"The 60-day threshold lives in the agent's system prompt — domain rules, not the LLM's invention."*

---

### A3 — Customer 360 (showcase L17: single-token name fix)
This is the **best single demo beat** because the live transcript bug fixed on 2026-05-05 disappears entirely.

| # | Prompt | What you'll see | Backed by |
|---|---|---|---|
| 1 | `Find customer Aditya.` | Single tool call → Aditya Srivatsava returned. **No "first or last name?" question.** No "which dealer?" question. | Live DB (id=97) |
| 2 | `Look up Mitchell.` | Sarah Mitchell (id=2) returned via last-name search | V18 seed |
| 3 | `Pull everything we have on Robert Garcia — deals, leads, finance apps.` | Multi-tool chain: find_customer + list_deals + list_leads + list_finance_apps | V18+V62+V71 |

**Talking point:** *"This used to be a 5-turn ladder — 'first or last name? what dealer code?' The fix wasn't smarter prompting; it was making the schema honest. The schema is a stronger signal than prose to a well-aligned LLM."*

**⚠ Note:** If "Aditya" doesn't return on the live demo, fall back to "Mitchell" — guaranteed by V18 seed.

---

### A4 — Pipeline / lead funnel
Multi-tool reasoning.

| # | Prompt | Expectation | Backed by |
|---|---|---|---|
| 1 | `How's our lead pipeline looking this month at DLR01? Where are leads getting stuck?` | 6 fresh leads, mix of NW/CT/QF/PR — agent narrates the funnel | V71 #3 |
| 2 | `Which lead source converts best at DLR01?` | Aggregates across all V62+V71 leads | V62+V71 |
| 3 | `Leads at DLR01 we haven't contacted in 7+ days?` | Mix from V62 stale + V71 fresh-but-cooling | V62+V71 |

---

### A5 — Federal recall cross-reference (NHTSA + vPIC) — **deck-worthy wow moment**

| # | Prompt | What you'll see | Notes |
|---|---|---|---|
| 1 | `Are there any open federal recalls on VIN 1HGCM82633A004352?` | Agent calls NHTSA, returns recall(s) | External API (live) |
| 2 | `Decode this VIN and check recalls: 1FTFW1ET5DFC10312` | vPIC decode + NHTSA lookup chained | Multi-tool |
| 3 | `Pull recall status for 2025 Ford F-150s in our inventory.` | Iterates over DLR01 F-150s + NHTSA lookup each | Multi-tool with chaining |

**Talking point:** *"This is local inventory data + live federal data, cross-referenced in one agent turn. Not in our DB."*

---

### A6 — Stale-workflow detection (anomaly)

| # | Prompt | Expectation | Backed by |
|---|---|---|---|
| 1 | `Any finance applications stuck in review more than 5 days? Who's blocking them?` | 2 stale SB applications (FIN71000004 / FIN71000005) | V71 #4 |
| 2 | `Show me deals stuck in credit-app status for more than 3 days at DLR01.` | DL01000204 (CA since 2026-05-10) and possibly older from V61 | V71 #2 |
| 3 | `Any open warranty claims older than a week?` | CL710002 (in review 5d) + older V65 claims | V71 #5 + V65 |

---

### A7 — Capability gap (loop closure — **end-of-demo move**)

| # | Prompt | Expected behavior | Demo move |
|---|---|---|---|
| 1 | `Delete customer 9001 from the system.` | Agent declines + logs gap + offers workaround pivot ("In the meantime, here's what I can do...") | Switch to `/admin/capability-gaps` — show the row landed |
| 2 | `Cancel deal DL01000003.` | Same shape — gap logged | Same |
| 3 | `Email Sarah Mitchell about her trade-in.` | Same shape — gap logged | Same |

**Talking point:** *"The agent doesn't self-update its weights — it self-reports its gaps. Every 'I can't do that' becomes a tracked backlog item. Compliance teams love this because the feedback loop is auditable."*

---

## 3. ACTION prompts (propose → confirm → audit)

### W1 — Create a lead (Tier A)
Shows the propose card + role gate.

| # | Prompt | What happens | Customer ref |
|---|---|---|---|
| 1 | `Create a hot lead for Sarah Mitchell — she's back in the market for a 2026 Bronco.` | ProposalCard appears amber → click Execute → row inserted, audit captured | id=2 |
| 2 | `Robert Garcia wants info on the new F-150. Create a lead, warm, walk-in.` | Same flow | id=3 |
| 3 | `Add a new lead for Aditya — referral source, interested in Explorer.` | Same flow | id=97 (live only) |

---

### W2 — Apply incentive (Tier A)

| # | Prompt | Notes |
|---|---|---|
| 1 | `Apply the $1,000 Model Year Clearance incentive to deal DL01000004.` | DL01000004 exists from V18-era seed |
| 2 | `Add a $500 Military Appreciation discount to DL01000201.` | V71 deal, just delivered |
| 3 | `Apply Loyalty Trade-in $750 to DL01000200.` | V71 deal |

---

### W3 — Add trade-in (Tier A, verified live previously)

| # | Prompt | Target | Customer-friendly framing |
|---|---|---|---|
| 1 | `Add a 2019 Honda Civic trade-in to DL01000203 — 45,000 miles, appraised at $14,000.` | DL01000203 is in WS (just opened today) | "Customer just brought in a Civic..." |
| 2 | `Trade-in for DL01000203: 2017 Camry, 78k miles, $11,500.` | Same WS deal | "Trying a different appraisal..." |
| 3 | `Add 2021 RAV4 trade, 22k miles, $24,000 to DL01000203.` | Same | "Premium trade-in" |

---

### W4 — Submit finance app (Tier A)

| # | Prompt | Target |
|---|---|---|
| 1 | `Submit a finance app for DL01000203 — 60 months, $5,000 down, prefer Ally Financial.` | WS deal — propose succeeds |
| 2 | `For DL01000203, run finance through Chase, 72 months, $3,000 down.` | Same |
| 3 | `Finance app on DL01000204 — 48 months, $8,000 down, lease structure.` | CA deal — may already have a stale SB app (FIN71000004) — could trigger interesting "already have one in review" path |

---

### W5 — Approve deal (Tier B, manager-only)

| # | Prompt | Target | Notes |
|---|---|---|---|
| 1 | `Approve deal DL01000204.` | DL01000204 in CA status — clean approval | ADMIN001 has manager-equivalent role |
| 2 | `Approve DL01000205.` | DL01000205 in AP status — already approved, may show "already approved" path | |
| 3 | `Approve DL01000203.` | WS status — will be **rejected** by dry-run preconditions (correct behavior — show this as a feature) | "The framework refused — that's the safety net" |

---

### W6 — Mark shipment arrived (Tier B)

| # | Prompt | Target |
|---|---|---|
| 1 | `Shipment SH26-0000201 just rolled in — mark it arrived.` | IT → DL transition |
| 2 | `SH26-0000202 has arrived at DLR06, mark it.` | Same |
| 3 | `Mark SH26-0000200 arrived.` | Already DL — should reject gracefully ("already delivered") |

---

### W7 — Close warranty claim (Tier B)

| # | Prompt | Target |
|---|---|---|
| 1 | `Close warranty claim CL710001 as approved, $850 reimbursement.` | NW → CL |
| 2 | `CL710002 — close it, paid in full ($1,105).` | AP → CL |
| 3 | `Close CL710003.` | Already CL — should reject ("already closed") |

---

## 4. HERO prompts (best for the close)

### H1 — Customer-360 → action chain (multi-tool, single turn)
**Prompt:** `Robert Garcia is in the showroom asking about a Mustang. Pull his history, what Mustangs we have in stock, and create a hot lead linked to a Mustang GT.`

→ Hits `find_customer` → `list_vehicles(model=MUSTANG)` → `[[PROPOSE]] create_lead` in one turn. Showcases reads + writes + safety in a single business moment.

### H2 — Glass-box trace finale
After any propose/confirm above, switch to `/admin/agent-trace/{conversationId}` and walk the tool-call timeline live.

**Talking point:** *"Every tool call. Every audit row. Every elapsed ms. Every payload. There's no off-screen magic. This is what the CIO sees when they ask 'is this safe?'."*

---

## 5. Recovery plays — if something doesn't work

| Symptom | Likely cause | Recovery |
|---|---|---|
| Agent stalls 30+ seconds on first prompt | Cold-start (Cloud Run scale-from-zero on backend dependency) | Wait ~45 s, retry. min-instances=1 should prevent this, but a fresh roll can re-trigger. |
| Agent says "I encountered an internal server error" | Likely a tool call hit a 4xx/5xx in the API — schema drift somewhere | Switch to a different prompt variation. Don't try to debug live — the trace UI will tell you which call broke. |
| Agent says "I don't know what 'past week' means" | L11 date injection regressed | Phrase as absolute: *"daily sales between May 4 and May 11 at DLR01"* |
| "Find customer Aditya" returns nothing | The live DB lost id=97 (rare) | Switch to *"Find customer Mitchell"* — guaranteed by V18 seed |
| Proposal card never appears for a write prompt | Agent didn't emit `[[PROPOSE]]` marker | Re-phrase to be more explicit: *"Use the create_lead tool to add..."* |
| Stuck spinner forever | The 2026-05-05 stale-proposal bug returns | Refresh the page. Stale proposal hygiene (commit 284ec73) cleans up on next turn anyway. |
| Quota exhausted on ADMIN001 (200K tokens/day) | Heavy testing earlier in the day | Log in as `EVALUSER` (1M-token quota), same Admin role |

---

## 6. Reference — what's in the database (for your own awareness)

### DLR01 customers (for entity-lookup prompts)
| ID | Name | Notes |
|---|---|---|
| 1 | Michael Henderson | V18-era, has multiple deals |
| 2 | Sarah Mitchell | V18-era, used in W1#1 |
| 3 | Robert Garcia | V18-era, used in H1 |
| 6 | Amanda Reyes | V18-era |
| 31 | Nathan Garza | V62 add |
| 32 | Olivia Bennett | V62 add |
| 82 | Jane Smith | created by agent at some point |
| 85 | Rajesh Ramadurai | created by agent |
| 89 | Shaneesh Nanu | created by agent |
| 97 | **Aditya Srivatsava** | created by agent — used in A3 |

### DLR01 deals (for write prompts)
| Deal # | Status | VIN | Notes |
|---|---|---|---|
| DL01000001-016 | DL/FI/NE/CA | various | V18-era seed |
| DL01000101-110 | DL/WS | various | V61 supplement |
| **DL01000200** | DL | 1FTFW1E53PFA01573 | V71 delivered 2026-05-02 |
| **DL01000201** | DL | 1FA6P8CF7N5A01571 | V71 delivered 2026-05-07 |
| **DL01000202** | DL | 1FM5K8GC7PGA01571 | V71 delivered 2026-05-10 |
| **DL01000203** | WS | 1FTFW1E53PFA01571 | V71 — opened today; **use for W3/W4** |
| **DL01000204** | CA | 1FTFW1E53PFA01572 | V71 — **use for W5** |
| **DL01000205** | AP | 1FMCU9J93NUA01573 | V71 — alternate W5 target |

### V71 shipments
| Shipment ID | Status | Dest | Notes |
|---|---|---|---|
| SH26-0000200 | DL | DLR01 | Arrived today — already delivered |
| **SH26-0000201** | IT | DLR01 | **Use for W6** |
| **SH26-0000202** | IT | DLR06 | **Alt W6 target** |

### V71 warranty claims (DLR01)
| Claim # | Status | VIN | Notes |
|---|---|---|---|
| **CL710001** | NW | 1FTFW1E53NFA01501 | Fresh, filed today — **use for W7** |
| **CL710002** | AP | 1FMCU9J93NUA01501 | In review — alt W7 target |
| CL710003 | CL | 1FA6P8CF7N5A01501 | Already closed |

### V71 stale finance apps
| Finance ID | Deal | Submitted | Notes |
|---|---|---|---|
| FIN71000004 | DL01000204 | 2026-05-05 | 6 days stale — A6#1 flag |
| FIN71000005 | DL06000200 | 2026-05-04 | 7 days stale — A6#1 flag |

---

## 7. After the demo

- Stop Cloud SQL if not demoing again same day: `./gcp/stop-sql.ps1` (drops cost to ~$1-2/mo)
- Resume next time: `./gcp/start-sql.ps1` (~30 s warmup)
- Capture any "wow moment" feedback into `project_pitch_deck_knowledge.md` for the deck
