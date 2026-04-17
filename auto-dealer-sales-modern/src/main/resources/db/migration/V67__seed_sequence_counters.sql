-- ==========================================================================
-- V67: Seed SEQ_* rows in system_config that the SequenceGenerator relies on.
--
-- com.autosales.common.util.SequenceGenerator generates dealNumber, financeId,
-- registrationId, transferId, shipmentId, stockNumber via SELECT ... FOR UPDATE
-- against system_config rows. None of V1-V66 seeded these — a latent gap since
-- all prior seed data hand-assigned IDs. Starting value 1000 is safely above
-- any hand-assigned numbers. Idempotent.
-- ==========================================================================

INSERT INTO system_config (config_key, config_value, config_desc, updated_by, updated_ts) VALUES
  ('SEQ_DEAL',         '1000', 'Next deal number (SequenceGenerator)',     'SEED', CURRENT_TIMESTAMP),
  ('SEQ_FINANCE',      '1000', 'Next finance ID (SequenceGenerator)',      'SEED', CURRENT_TIMESTAMP),
  ('SEQ_REGISTRATION', '1000', 'Next registration ID (SequenceGenerator)', 'SEED', CURRENT_TIMESTAMP),
  ('SEQ_TRANSFER',     '1000', 'Next transfer ID (SequenceGenerator)',     'SEED', CURRENT_TIMESTAMP),
  ('SEQ_SHIPMENT',     '1000', 'Next shipment ID (SequenceGenerator)',     'SEED', CURRENT_TIMESTAMP),
  ('SEQ_STOCK',        '1000', 'Next stock number (SequenceGenerator)',    'SEED', CURRENT_TIMESTAMP)
ON CONFLICT (config_key) DO NOTHING;
