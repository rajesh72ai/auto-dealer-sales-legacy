# Two AI Surfaces, One Dealership
### AUTOSALES Dual-AI Story — Pitch Narrative

> Narrative source of truth for `AUTOSALES_Dual_AI_Pitch.pptx`.
> Generator: `generate_dual_ai_deck.py`.
> Scope: AUTOSALES only. Portfolio-wide story is told separately in claude-common.

---

## Slide 1 — Title
**Two AI Surfaces, One Dealership**
*How AUTOSALES moved from green-screen transactions to a system that thinks alongside the dealer.*

Subtitle: AI Assistant + AI Agent — shipped 2026-04-14.

---

## Slide 2 — The Evolution Ladder
Mainframe modernization isn't just replacing screens. It's giving the dealer a second kind of help — help that *reasons*.

| Era | Interaction | Human does | System does |
|---|---|---|---|
| IMS DC (1990s) | Green screen, PF keys | Knows every screen + transaction code | Executes the exact transaction |
| React UI (2026) | Forms, pages, filters | Clicks through workflows | Shows data, validates input |
| **AI Assistant** | Chat box | Asks *one* question | Fetches *one* answer |
| **AI Agent** | Chat box | States a *goal* | Plans, chains tools, reasons, recommends |

**Punchline:** The Agent is the first time the software does the thinking the clerk used to do.

---

## Slide 3 — Meet the Assistant (Blue)
Endpoint: `/api/chat` · Backend: `ChatService` · LLMs: Groq / Gemini / Together / Mistral (user-picked)

- **Tagline:** *"Google for your dealership."*
- Cheap, fast, single-step, free-tier
- Use when: you know what you want, you just need it faster than clicking
- Sample: *"What's customer 42's phone number?"* → one API call, one answer

Widget: blue pill in header, provider dropdown, ~1-2s response.

---

## Slide 4 — Meet the Agent (Violet)
Endpoint: `/api/agent` · Backend: `AgentService` → `OpenClawClient` → gateway · LLM: Claude Sonnet 4.6

- **Tagline:** *"A junior analyst on staff."*
- Premium, deliberate, multi-step, skills-based (Level 4 agentic)
- Use when: you have a goal, not a question
- Sample: *"Is deal 17 healthy?"* → pulls deal, credit, finance app, inventory, applies aging + APR + approval rules, flags three risks

Widget: violet pill in header, no provider dropdown, 20–40s with "Planning and running tools…" indicator.

---

## Slide 5 — Four Differentiation Axes

1. **Cognitive load** — Assistant answers *your* question; Agent decides *which questions matter*
2. **Tool-call depth** — 1 call vs 4–8 chained calls with domain rules applied between steps
3. **Cost & latency** — free & instant vs ~$0.05 & 20–40s (value gap justifies the trade)
4. **Architecture** — single LLM call vs skills-based agent: `SKILL.md` progressive disclosure, 28 tools, 5 recipes, OpenClaw gateway

---

## Slide 6 — Same Question, Two Answers (The Demo)
Prompt to both surfaces: *"Give me a morning briefing."*

**Assistant answer** (~2s, 1 call):
> *"Here are today's deals: [list of 17 rows]."*

**Agent answer** (~30s, 6 chained calls + domain rules):
> *"Good morning. 3 things need you today:*
> *1. Deal #17 has been at UW for 9 days — credit check is stale, customer Johnson hasn't been contacted since Tuesday.*
> *2. VIN 1HG… has been on the lot 72 days, 12 over floor-plan exposure limit — suggest transfer to DLR02 who's short on sedans.*
> *3. Warranty claim #44 crosses the 14-day escalation threshold tomorrow."*

Same data. Radically different value.

---

## Slide 7 — Five Workflow Recipes
Shipped in `openclaw/skills/autosales-api/SKILL.full.md`:

1. **Deal Health Check** — state machine status + SLA aging + missing docs
2. **Customer 360** — referral graph + stale-data flags + loyalty signals
3. **Lead-to-Deal Funnel** — conversion diagnostics, stalled stages
4. **Inventory Aging Triage** — 60-day rule + floor-plan exposure + cross-dealer transfer hints
5. **Morning Briefing** — composite rollup across all four above

Each recipe encodes the domain rules a dealer would apply by hand.

---

## Slide 8 — Under the Hood
```
┌──────────────┐   POST /api/agent   ┌────────────────┐   POST /v1/chat/completions   ┌──────────────────┐
│ React UI     │ ──────────────────▶ │ AgentController│ ────────────────────────────▶ │ OpenClaw Gateway │
│ AgentWidget  │ ◀────────────────── │ AgentService   │                               │  (:18789)        │
└──────────────┘     {reply,model}   └────────────────┘                               └──────────────────┘
                                                                                               │
                              ┌──────────────────────────────────────┐                         ▼
                              │ SKILL.md  (lean trigger ~30 lines)   │ ◀──── progressive ──── Claude Sonnet 4.6
                              │ SKILL.full.md (payload ~230 lines)   │       disclosure         (Anthropic plugin)
                              │   • 28 tool catalog                  │
                              │   • 5 workflow recipes               │
                              │   • Domain rules (aging, APR, SSN…)  │
                              └──────────────────────────────────────┘
                                               │
                                               ▼  X-API-Key
                              ┌────────────────────────────────┐
                              │ AUTOSALES REST API (28 tools)  │
                              └────────────────────────────────┘
```
Auth: JWT at `/api/agent`, static `X-API-Key` gateway → app, Anthropic API key in `.env`.

---

## Slide 9 — What's Next
- **Tool-call visibility** — SSE streaming so the agent's plan is visible as it runs
- **Server-side conversation memory** — per-userId history, enables longer multi-turn
- **Composite tools** — `get_customer_360(id)` as a single orchestrated call, fewer LLM round-trips
- **More recipes** — Finance deal review, Inventory rebalance, Recall impact report
- **External `web_fetch`** — NHTSA recall data, KBB pricing, VIN-decode enhancements
- **Cost guardrails** — monthly cap + per-user quota
