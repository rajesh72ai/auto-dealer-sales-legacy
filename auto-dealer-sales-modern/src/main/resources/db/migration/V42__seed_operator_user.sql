-- OpenClaw AI operator user (read-only + safe actions)
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag)
VALUES ('OPER_AI', 'OpenClaw AI Operator', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'O', 'DLR01', 'Y');
