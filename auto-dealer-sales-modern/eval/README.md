# Agent regression eval (v1)

A small, deterministic regression suite for the AUTOSALES agent. Each YAML in
`prompts/` describes a prompt + expectations; the runner drives the live agent
over HTTP and asserts the response shape + tool-call audit trail.

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
automatically. Schema (all fields under `expect:` are optional):

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
  latency_ms_max: 30000
  tokens_total_max: 12000
  proposal:                 # null = expect no proposal; object = check shape
    tool_name: create_lead  # required
flaky: false                # if true, runner retries up to 3× and accepts 2 passes
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
- **No long-session corpus yet.** Each prompt is a single turn. Multi-turn
  state-corruption probes are the next investment after the v1 runner is
  stable.
