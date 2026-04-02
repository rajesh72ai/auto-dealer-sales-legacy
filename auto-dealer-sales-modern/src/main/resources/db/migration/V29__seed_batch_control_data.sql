-- ============================================================
-- V29: Seed batch_control with all 11 legacy batch programs
-- Maps to BATDLY00, BATMTH00, BATPUR00, BATVAL00, BATWKL00,
--          BATCRM00, BATDLAKE, BATDMS00, BATGLINT, BATINB00, BATRSTRT
-- ============================================================

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATDLY00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATMTH00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATPUR00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATVAL00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATWKL00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATCRM00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATDLAKE', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATDMS00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATGLINT', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATINB00', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO batch_control (program_id, last_run_date, last_sync_date, records_processed, run_status, created_ts, updated_ts)
VALUES ('BATRSTRT', NULL, NULL, 0, 'NR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
