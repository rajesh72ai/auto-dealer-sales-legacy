-- Phase 3 Safe Action Framework: short-lived proposal tokens that carry
-- the dry-run preview the user will confirm. Binds (user, tool, payloadHash)
-- so a captured token can't be replayed with a different payload.

CREATE TABLE agent_action_proposal (
    token            VARCHAR(36)    PRIMARY KEY,
    user_id          VARCHAR(20)    NOT NULL,
    dealer_code      VARCHAR(10),
    conversation_id  VARCHAR(36),
    tool_name        VARCHAR(64)    NOT NULL,
    tier             VARCHAR(1)     NOT NULL,
    payload_json     TEXT           NOT NULL,
    payload_hash     VARCHAR(64)    NOT NULL,
    preview_json     TEXT           NOT NULL,
    status           VARCHAR(20)    NOT NULL,
    expires_at       TIMESTAMP      NOT NULL,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decided_at       TIMESTAMP,
    execution_audit_id BIGINT
);

CREATE INDEX idx_proposal_user_pending ON agent_action_proposal (user_id, status);
CREATE INDEX idx_proposal_expires      ON agent_action_proposal (expires_at)
    WHERE status = 'PENDING';

COMMENT ON TABLE  agent_action_proposal IS 'Pending dry-run previews awaiting user confirm/reject';
COMMENT ON COLUMN agent_action_proposal.status       IS 'PENDING | CONFIRMED | REJECTED | EXPIRED';
COMMENT ON COLUMN agent_action_proposal.payload_hash IS 'SHA-256 of payload_json — prevents replay with altered payload';
