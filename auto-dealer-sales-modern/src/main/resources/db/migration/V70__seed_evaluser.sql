-- ============================================================
-- AUTOSALES Seed Data: EVALUSER for the agent regression suite
-- User ID: EVALUSER, Password: Admin123 (reused hash from ADMIN001)
-- Role: ADMIN (needed for /api/admin/agent-trace audit fetch)
-- Dealer: DLR01
-- Quota: 1,000,000 daily tokens — ~5x the demo default (200K) so eval
--        iteration doesn't drain the demo account, and the eval's token
--        spend is auditable separately on the Anthropic / Vertex AI cost
--        dashboards by user_id.
--
-- See eval/README.md for the test runner docs and project_session_*
-- memory files for the rationale (separate eval-automation user).
-- ============================================================

INSERT INTO "system_user" (
    user_id, user_name, password_hash, user_type, dealer_code, active_flag,
    agent_daily_token_quota, agent_enabled, agent_notes
)
VALUES (
    'EVALUSER',
    'Agent Eval Automation',
    '$2a$10$f6CP7ChaxTQEuKGMpfqHLuyHDbU36H.DxLS7WAFr6bWoZ.476pePG',
    'A',
    'DLR01',
    'Y',
    1000000,
    TRUE,
    'Eval automation — bumped quota for AgentRegressionTest. Same password as ADMIN001.'
);
