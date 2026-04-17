-- Agent conversation persistence for the AI Agent surface (Claude via OpenClaw).
-- Enables server-side history so the frontend only sends the current turn and
-- the server reconstructs context — cuts token cost on multi-turn conversations
-- and provides an audit trail for compliance.

CREATE TABLE agent_conversation (
    conversation_id  VARCHAR(36)  PRIMARY KEY,
    user_id          VARCHAR(10)  NOT NULL,
    dealer_code      VARCHAR(5),
    title            VARCHAR(200),
    model            VARCHAR(80),
    turn_count       INTEGER      NOT NULL DEFAULT 0,
    token_total      INTEGER      NOT NULL DEFAULT 0,
    created_ts       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_conv_user ON agent_conversation (user_id, updated_ts DESC);

CREATE TABLE agent_message (
    message_id       BIGSERIAL    PRIMARY KEY,
    conversation_id  VARCHAR(36)  NOT NULL REFERENCES agent_conversation(conversation_id) ON DELETE CASCADE,
    role             VARCHAR(16)  NOT NULL,
    content          TEXT         NOT NULL,
    seq              INTEGER      NOT NULL,
    created_ts       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_msg_conv ON agent_message (conversation_id, seq);
