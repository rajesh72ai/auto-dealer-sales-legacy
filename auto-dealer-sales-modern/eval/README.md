# Agent regression eval (v1.5)

A small, deterministic regression suite for the AUTOSALES agent. Each YAML in
`prompts/` describes a prompt (or a multi-turn sequence) + expectations; the
runner drives the live agent over HTTP and asserts the response shape +
tool-call audit trail.

## Why this exists
Every change to the agent (system prompt, tool catalog, classification rules,
schema) used to be verified by hand-smoke. That works for a one-engineer pace;
it does not survive model upgrades, rule-set churn, or two months of drift. The
corpus here is the regression net — each entry maps to a captured lesson
(L1–L14 in `project_agent_lessons_learned.md`) so a fix becomes a guarding
test, not just a one-time bug squash.

## Run it
The corpus is **opt-in**. `mvn test` skips it (the test class is gated on a
system property so it never runs in normal cycles).

```powershell
# Pick a target — typically the live frontend Cloud Run URL.
$target = & "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" `
    run services describe autosales-frontend `
    --project=auto-sales-ai-enabled --region=us-central1 `
    --format='value(status.url)'

cd auto-dealer-sales-modern
./mvnw.cmd test -Dtest=AgentRegressionTest -Deval.run=true -Deval.target=$target
```

Artifacts:
- Console output — one line per prompt: `[PASS|FAIL] t-id — reason`
- `target/eval-report.md` — detailed per-prompt timing, assertion breakdown,
  tool calls observed; paste into a PR description

## Adding a prompt
Drop a new `t-<slug>.yml` under `prompts/`. The runner picks it up
automatically. Two shapes are supported.

### Single-turn (legacy)

```yaml
id: t-my-new-test
description: One-line summary (shows up in the report)
prompt: "What the user types into the agent"
auth:
  user_id: EVALUSER          # dedicated automation user with bumped quota (V70)
  password: Admin123
expect:
  reply_contains:           # plain substrings (all must be present)
    - "DLR01"
  reply_not_contains:       # substrings that must NOT appear
    - "2024"
  reply_matches:            # regex patterns (all must match somewhere)
    - "\\d+ vehicles?"
  tool_calls_include:       # tool names that MUST appear in the audit
    - get_stock_summary
  tool_calls_exclude:       # tool names that MUST NOT appear
    - find_customer
  tool_calls_args:          # subset match against parsed payload_json
    list_deals:
      dealerCode: DLR01
  tool_calls_tier: R        # filter rows to R (read) or A (action) before above
  latency_ms_max: 30000
  tokens_total_max: 12000
  proposal:                 # null = expect no proposal; object = check shape
    tool_name: create_lead
    # — or —
    tool_name_any_of:       # accept any of these (use for chains that decompose)
      - create_lead
      - create_customer
flaky: false                # if true, runner retries up to 3× and accepts 2 passes
```

### Multi-turn

For testing cross-turn state, use `turns:` instead of top-level
`prompt`+`expect`. The driver reuses the conversationId across turns and
partitions audit rows by an auditId high-water mark so each turn's
assertions only see that turn's tool calls.

```yaml
id: t-my-multi-turn-test
description: Two-turn scenario testing entity-state reuse
auth:
  user_id: EVALUSER
  password: Admin123
flaky: false
turns:
  - prompt: "Find customer Sarah Mitchell at DLR01"
    expect:
      reply_contains: ["Sarah", "Mitchell"]
      tool_calls_include: [find_customer]
      tool_calls_tier: R
      proposal: null
  - prompt: "Now create a lead for her at DLR01, leadSource WLK"
    expect:
      tool_calls_exclude: [find_customer, list_customers]
      tool_calls_tier: R
      proposal:
        tool_name_any_of: [create_lead]
```

## Design notes
- **Loose-by-default assertions.** LLMs aren't deterministic. We assert shape
  (regex / set membership / range), never exact text.
- **Real production path.** We hit the live deploy via HTTPS, log in with a
  real user, get a real JWT, post to `/api/agent`, then read
  `/api/admin/agent-trace/{conversationId}` to verify the tool-call audit.
  Skips no integration layer.
- **No nightly run yet.** Manual trigger only. v2 wires Cloud Scheduler →
  Cloud Run job and adds a trend dashboard.
- **Multi-turn corpus is small (1 prompt).** First multi-turn case landed in
  v1.5 — `t-multi-deictic-customer-ref` validates that deictic references
  ("her", "that customer") resolve correctly without re-verification. Future
  multi-turn probes: truncation boundary (turn 21+), multi-entity ambiguity
  (find A, find B, then "her"), prose without explicit ID.
