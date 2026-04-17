-- V68: Reusable capability-gap logging table.
-- Records every time the AI agent (or any AI surface) refuses a user request
-- because the capability isn't implemented. Feeds a product backlog by showing
-- real demand patterns.

CREATE TABLE capability_gap_log (
    gap_id              BIGSERIAL       PRIMARY KEY,
    app_id              VARCHAR(30)     NOT NULL DEFAULT 'AUTOSALES',
    app_name            VARCHAR(100)    NOT NULL DEFAULT 'Auto Dealer Sales',
    source_system       VARCHAR(30)     NOT NULL DEFAULT 'AGENT',
    user_id             VARCHAR(20),
    dealer_code         VARCHAR(10),
    requested_capability VARCHAR(100)   NOT NULL,
    category            VARCHAR(30)     NOT NULL DEFAULT 'UNKNOWN',
    user_input          TEXT            NOT NULL,
    scenario_description TEXT           NOT NULL,
    agent_reasoning     TEXT            NOT NULL,
    suggested_alternative TEXT,
    priority_hint       VARCHAR(10)     NOT NULL DEFAULT 'MEDIUM',
    status              VARCHAR(20)     NOT NULL DEFAULT 'NEW',
    resolution_notes    TEXT,
    created_ts          TIMESTAMP       NOT NULL DEFAULT NOW(),
    resolved_ts         TIMESTAMP
);

CREATE INDEX idx_capability_gap_app_id      ON capability_gap_log(app_id);
CREATE INDEX idx_capability_gap_capability ON capability_gap_log(requested_capability);
CREATE INDEX idx_capability_gap_category   ON capability_gap_log(category);
CREATE INDEX idx_capability_gap_status     ON capability_gap_log(status);
CREATE INDEX idx_capability_gap_created    ON capability_gap_log(created_ts);

COMMENT ON TABLE capability_gap_log IS 'Product feedback loop: logs AI capability gaps surfaced during user interactions. Reusable across applications.';
COMMENT ON COLUMN capability_gap_log.app_id IS 'Short identifier for the application — AUTOSALES, CARDDEMO, GENAPP, PORTFOLIO. Enables portfolio/org-level rollup.';
COMMENT ON COLUMN capability_gap_log.app_name IS 'Human-readable application name for display — e.g. Auto Dealer Sales, Card Demo, etc.';
COMMENT ON COLUMN capability_gap_log.source_system IS 'Which AI surface logged this — AGENT, ASSISTANT, CHAT, etc.';
COMMENT ON COLUMN capability_gap_log.requested_capability IS 'The tool/action the user wanted — e.g. create_customer, delete_vehicle';
COMMENT ON COLUMN capability_gap_log.category IS 'Broad category: CRUD, CONFIG, BATCH, REPORTING, WORKFLOW, INTEGRATION';
COMMENT ON COLUMN capability_gap_log.user_input IS 'The user''s actual prompt text (verbatim or summarized)';
COMMENT ON COLUMN capability_gap_log.scenario_description IS 'What the user was trying to accomplish end-to-end';
COMMENT ON COLUMN capability_gap_log.agent_reasoning IS 'Why the AI could not fulfill the request — allow-list gap, missing tool, role restriction, etc.';
COMMENT ON COLUMN capability_gap_log.suggested_alternative IS 'What the AI suggested instead (use the UI, contact clerk, etc.)';
COMMENT ON COLUMN capability_gap_log.priority_hint IS 'AI assessment: LOW, MEDIUM, HIGH, CRITICAL';
COMMENT ON COLUMN capability_gap_log.status IS 'Backlog lifecycle: NEW, REVIEWED, PLANNED, IMPLEMENTED, WONT_DO';
