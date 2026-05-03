-- Per-user AI agent access policy + token quota override (B-tokenadmin).
-- Three columns added to system_user instead of a separate table because:
--   - Same lifecycle as user
--   - Single-valued per user
--   - No special governance; just admin-edited attributes
--   - Existing User Management page handles them inline
-- See feedback_avoid_table_overengineering.md for the design rationale.

ALTER TABLE "system_user"
    ADD COLUMN agent_daily_token_quota INTEGER,
    ADD COLUMN agent_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN agent_notes VARCHAR(200);

COMMENT ON COLUMN "system_user".agent_daily_token_quota IS
    'Per-user override of the global agent.token-quota.daily-default. NULL = use system default.';
COMMENT ON COLUMN "system_user".agent_enabled IS
    'When FALSE the AI agent is disabled for this user — agent endpoint returns "Agent access disabled" without consuming any quota.';
COMMENT ON COLUMN "system_user".agent_notes IS
    'Free-text admin note explaining the policy (e.g. "Contractor — no AI access" or "Senior analyst — bumped quota").';
