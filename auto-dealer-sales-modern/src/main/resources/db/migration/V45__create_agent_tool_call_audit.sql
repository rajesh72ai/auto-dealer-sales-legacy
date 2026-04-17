-- Phase 3 Safe Action Framework: per-tool-call audit trail for agent writes.
-- Separate from audit_log (which tracks @Auditable CRUD) because agent calls
-- need conversation correlation, preview JSON, and proposal/confirm/execute lifecycle.

CREATE TABLE agent_tool_call_audit (
    audit_id           BIGSERIAL     PRIMARY KEY,
    user_id            VARCHAR(20)   NOT NULL,
    user_role          VARCHAR(1),
    dealer_code        VARCHAR(10),
    conversation_id    VARCHAR(36),
    proposal_token     VARCHAR(36),
    tool_name          VARCHAR(64)   NOT NULL,
    tier               VARCHAR(1)    NOT NULL,
    endpoint           VARCHAR(200),
    http_method        VARCHAR(10),
    payload_json       TEXT,
    preview_json       TEXT,
    response_json      TEXT,
    status             VARCHAR(20)   NOT NULL,
    http_status        INTEGER,
    error_message      VARCHAR(500),
    elapsed_ms         INTEGER,
    dry_run            BOOLEAN       NOT NULL DEFAULT FALSE,
    reversible         BOOLEAN       NOT NULL DEFAULT FALSE,
    compensation_json  TEXT,
    undo_expires_at    TIMESTAMP,
    undone             BOOLEAN       NOT NULL DEFAULT FALSE,
    undone_at          TIMESTAMP,
    created_ts         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_audit_user_date ON agent_tool_call_audit (user_id, created_ts DESC);
CREATE INDEX idx_agent_audit_tool      ON agent_tool_call_audit (tool_name, created_ts DESC);
CREATE INDEX idx_agent_audit_conv      ON agent_tool_call_audit (conversation_id);
CREATE INDEX idx_agent_audit_proposal  ON agent_tool_call_audit (proposal_token);

COMMENT ON TABLE  agent_tool_call_audit IS 'Per-tool-call audit for agent write actions (propose/confirm/execute lifecycle)';
COMMENT ON COLUMN agent_tool_call_audit.status            IS 'PROPOSED | CONFIRMED | REJECTED | EXECUTED | FAILED';
COMMENT ON COLUMN agent_tool_call_audit.tier              IS 'A=sales, B=manager, C=operator, D=chained';
COMMENT ON COLUMN agent_tool_call_audit.dry_run           IS 'True when this row represents a dry-run preview (no real write)';
COMMENT ON COLUMN agent_tool_call_audit.reversible        IS 'True if tool supports undo (structural — undo not activated in v1)';
COMMENT ON COLUMN agent_tool_call_audit.compensation_json IS 'Inverse-action payload serialized for future undo (not consumed in v1)';
COMMENT ON COLUMN agent_tool_call_audit.undo_expires_at   IS 'Scaffolding for Mobile-style Undo window (not activated in v1)';
