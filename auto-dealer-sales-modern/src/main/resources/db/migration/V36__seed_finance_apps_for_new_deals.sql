-- V36: Finance apps for the new AP-status deals and pending finance apps
-- Also add finance apps with different statuses (NW, CD, DN) for variety

INSERT INTO finance_app (finance_id, deal_number, customer_id, finance_type, lender_code, lender_name, app_status, amount_requested, amount_approved, apr_requested, apr_approved, term_months, monthly_payment, down_payment, credit_tier, stipulations, submitted_ts, decision_ts, funded_ts) VALUES
-- New AP deal DL01000026 - approved finance
('FA000000016', 'DL01000026', 6, 'L', 'ALLY1', 'Ally Financial', 'AP', 41718.40, 41718.40, 5.900, 5.490, 72, 684.21, 7000.00, 'B', NULL, '2025-10-01 14:00:00', '2025-10-01 15:30:00', NULL),

-- New AP deal DL02000027 - approved finance
('FA000000017', 'DL02000027', 12, 'L', 'CHASE', 'Chase Auto Finance', 'AP', 30552.63, 30552.63, 6.500, 5.990, 60, 590.50, 4000.00, 'C', 'Proof of income required', '2025-10-02 10:00:00', '2025-10-02 11:45:00', NULL),

-- New AP deal DL05000030 - approved finance
('FA000000018', 'DL05000030', 30, 'L', 'BMWFS', 'BMW Financial Services', 'AP', 34130.97, 34130.97, 4.500, 3.990, 60, 629.78, 8000.00, 'A', NULL, '2025-10-03 11:00:00', '2025-10-03 11:45:00', NULL),

-- DL01000004 (NE status) - new finance app submitted
('FA000000019', 'DL01000004', 4, 'L', 'ALLY1', 'Ally Financial', 'NW', 37260.82, NULL, 6.900, NULL, 72, NULL, 3000.00, 'C', NULL, '2025-09-30 16:00:00', NULL, NULL),

-- DL04000019 (NE status) - conditional approval
('FA000000020', 'DL04000019', 22, 'L', 'CHASE', 'Chase Auto Finance', 'CD', 49172.99, 42000.00, 7.500, 7.990, 72, 718.50, 5000.00, 'D', 'Max $42K, proof of residence, 2 pay stubs', '2025-09-29 14:00:00', '2025-09-30 09:30:00', NULL),

-- DL03000015 (NE lease) - declined first try
('FA000000021', 'DL03000015', 17, 'S', 'CHASE', 'Chase Auto Finance', 'DN', 40544.00, NULL, 3.900, NULL, 36, NULL, 0.00, NULL, 'Insufficient credit history', '2025-09-30 11:00:00', '2025-09-30 14:00:00', NULL);
