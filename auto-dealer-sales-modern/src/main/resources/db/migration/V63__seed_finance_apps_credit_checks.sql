-- ==========================================================================
-- V63: Finance apps + credit checks for new V61 deals
-- ~70 finance apps for delivered deals, mixed lender + tier distribution.
-- ~45 credit checks with persona-aware score distribution.
-- deal_number references V61 deals. customer_id fetched via deal subquery.
-- ==========================================================================

-- ── Finance Applications ─────────────────────────────────────────────
-- Pattern: use subquery to match customer_id from sales_deal
INSERT INTO finance_app (finance_id, deal_number, customer_id, finance_type, lender_code, lender_name, app_status, amount_requested, amount_approved, apr_requested, apr_approved, term_months, monthly_payment, down_payment, credit_tier, submitted_ts, decision_ts, funded_ts) VALUES
-- DLR01 deals (volume leader — ALLY/CHASE mix, mostly A/B tier)
('FIN60000101', 'DL01000101', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000101'), 'R', 'ALLY1', 'Ally Financial',        'FN', 41549.94, 41549.94, 6.250, 5.900, 60, 803.45, 8000.00,  'A', '2025-11-15 10:30:00', '2025-11-15 14:20:00', '2025-11-18 09:15:00'),
('FIN60000102', 'DL01000102', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000102'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 39549.94, 39549.94, 6.750, 6.450, 72, 663.22, 10000.00, 'B', '2025-12-22 11:10:00', '2025-12-22 15:40:00', '2025-12-27 10:00:00'),
('FIN60000103', 'DL01000103', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000103'), 'R', 'ALLY1', 'Ally Financial',        'FN', 38982.75, 38982.75, 6.500, 5.750, 60, 749.85, 12000.00, 'A', '2026-02-10 09:45:00', '2026-02-10 13:30:00', '2026-02-14 09:30:00'),
('FIN60000104', 'DL01000104', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000104'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 41482.75, 41482.75, 7.000, 6.750, 72, 703.10, 9500.00,  'B', '2026-03-18 14:20:00', '2026-03-18 17:55:00', '2026-03-22 10:15:00'),
('FIN60000105', 'DL01000105', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000105'), 'R', 'ALLY1', 'Ally Financial',        'FN', 33729.05, 33729.05, 6.250, 5.900, 60, 651.92, 6500.00,  'A', '2026-01-04 10:15:00', '2026-01-04 13:50:00', '2026-01-08 09:40:00'),
('FIN60000106', 'DL01000106', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000106'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 35229.05, 35229.05, 6.500, 6.250, 60, 686.90, 5000.00,  'B', '2026-03-22 11:45:00', '2026-03-22 15:20:00', '2026-03-26 10:30:00'),
('FIN60000107', 'DL01000107', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000107'), 'R', 'ALLY1', 'Ally Financial',        'FN', 33322.92, 33322.92, 6.250, 5.750, 60, 642.30, 15000.00, 'A', '2026-02-14 09:30:00', '2026-02-14 13:15:00', '2026-02-18 10:20:00'),
('FIN60000108', 'DL01000108', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000108'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 45350.55, 45350.55, 7.250, 6.900, 72, 768.40, 12500.00, 'B', '2026-03-30 14:50:00', '2026-03-30 18:30:00', '2026-04-03 11:00:00'),
('FIN60000109', 'DL01000109', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000109'), 'R', 'ALLY1', 'Ally Financial',        'FN', 46954.45, 46954.45, 6.500, 6.150, 72, 779.90, 11000.00, 'A', '2026-04-13 10:40:00', '2026-04-13 14:25:00', '2026-04-15 09:50:00'),
('FIN60000110', 'DL01000110', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000110'), 'R', 'ALLY1', 'Ally Financial',        'SB', 40000.00, NULL,     6.500, NULL,  NULL, NULL,  10000.00, NULL, '2026-04-15 15:20:00', NULL,                  NULL),
-- DLR06 deals (volume leader #2)
('FIN60000201', 'DL06000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000001'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 35013.96, 35013.96, 6.500, 6.250, 60, 682.75, 6000.00,  'B', '2026-01-09 11:20:00', '2026-01-09 15:00:00', '2026-01-13 09:30:00'),
('FIN60000202', 'DL06000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000002'), 'R', 'ALLY1', 'Ally Financial',        'FN', 39319.91, 39319.91, 6.750, 6.500, 72, 659.40, 10000.00, 'B', '2026-03-16 10:30:00', '2026-03-16 14:10:00', '2026-03-20 09:45:00'),
('FIN60000203', 'DL06000003', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000003'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 41077.95, 41077.95, 7.250, 7.000, 72, 698.20, 9500.00,  'B', '2026-01-28 14:15:00', '2026-01-28 17:45:00', '2026-02-02 10:20:00'),
('FIN60000204', 'DL06000004', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000004'), 'R', 'ALLY1', 'Ally Financial',        'FN', 38577.95, 38577.95, 6.500, 6.000, 60, 746.15, 12000.00, 'A', '2026-02-20 09:45:00', '2026-02-20 13:30:00', '2026-02-24 10:00:00'),
('FIN60000205', 'DL06000005', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000005'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 40548.64, 40548.64, 6.750, 6.500, 72, 680.85, 11500.00, 'B', '2026-03-12 11:00:00', '2026-03-12 14:40:00', '2026-03-16 09:50:00'),
('FIN60000206', 'DL06000006', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000006'), 'R', 'ALLY1', 'Ally Financial',        'FN', 39048.64, 39048.64, 6.250, 5.900, 60, 754.95, 13000.00, 'A', '2026-04-05 10:20:00', '2026-04-05 13:55:00', '2026-04-09 10:15:00'),
('FIN60000207', 'DL06000007', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000007'), 'R', 'CPTL1', 'Capital One Auto',      'SB', 38000.00, NULL,     7.000, NULL,  NULL, NULL,  10000.00, NULL, '2026-04-14 16:30:00', NULL,                  NULL),
('FIN60000208', 'DL06000008', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000008'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 45097.09, 45097.09, 7.000, 6.750, 72, 763.95, 14000.00, 'B', '2026-03-08 11:30:00', '2026-03-08 15:10:00', '2026-03-12 10:00:00'),
('FIN60000209', 'DL06000009', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000009'), 'R', 'TDAFC', 'TD Auto Finance',       'CD', 47203.72, 47203.72, 6.750, 6.500, 72, 791.60, 12000.00, 'B', '2026-04-10 14:20:00', '2026-04-10 18:00:00', NULL),
('FIN60000210', 'DL06000010', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000010'), 'R', 'ALLY1', 'Ally Financial',        'FN', 33513.96, 33513.96, 6.250, 6.000, 60, 647.80, 7500.00,  'A', '2026-03-30 10:15:00', '2026-03-30 13:50:00', '2026-04-02 09:30:00'),
('FIN60000211', 'DL06000011', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000011'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 35513.96, 35513.96, 6.500, 6.250, 60, 692.45, 5500.00,  'B', '2025-11-18 11:45:00', '2025-11-18 15:20:00', '2025-11-22 10:10:00'),
('FIN60000212', 'DL06000012', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000012'), 'R', 'ALLY1', 'Ally Financial',        'FN', 31319.91, 31319.91, 6.000, 5.750, 60, 603.80, 18000.00, 'A', '2026-02-05 09:50:00', '2026-02-05 13:35:00', '2026-02-09 10:00:00'),
-- DLR02 Luxury — all A tier, BMW-level rates
('FIN60000301', 'DL02000101', (SELECT customer_id FROM sales_deal WHERE deal_number='DL02000101'), 'R', 'ALLY1', 'Ally Financial',        'FN', 41237.10, 41237.10, 5.900, 5.500, 60, 789.15, 8000.00,  'A', '2025-12-22 14:30:00', '2025-12-22 18:10:00', '2025-12-27 09:45:00'),
('FIN60000302', 'DL02000102', (SELECT customer_id FROM sales_deal WHERE deal_number='DL02000102'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 37237.10, 37237.10, 5.750, 5.250, 60, 708.50, 12000.00, 'A', '2026-03-13 10:45:00', '2026-03-13 14:25:00', '2026-03-17 09:30:00'),
('FIN60000303', 'DL02000103', (SELECT customer_id FROM sales_deal WHERE deal_number='DL02000103'), 'L', 'ALLY1', 'Ally Financial',        'FN', 44237.10, 44237.10, 5.500, 5.000, 36, 615.40, 5000.00,  'A', '2026-04-12 11:20:00', '2026-04-12 14:55:00', '2026-04-14 10:00:00'),
('FIN60000304', 'DL02000104', (SELECT customer_id FROM sales_deal WHERE deal_number='DL02000104'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 26835.92, 26835.92, 6.000, 5.750, 60, 518.40, 7000.00,  'A', '2026-02-10 15:30:00', '2026-02-10 19:00:00', '2026-02-14 09:45:00'),
-- DLR07 Luxury BMW — premium lender
('FIN60000401', 'DL07000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL07000001'), 'L', 'BMWFS', 'BMW Financial Services','FN', 46459.16, 46459.16, 4.900, 4.500, 36, 1293.20, 5000.00,  'A', '2025-12-20 14:00:00', '2025-12-20 17:40:00', '2025-12-23 09:30:00'),
('FIN60000402', 'DL07000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL07000002'), 'R', 'BMWFS', 'BMW Financial Services','FN', 36459.16, 36459.16, 5.250, 4.750, 60, 687.20, 15000.00, 'A', '2026-02-22 11:30:00', '2026-02-22 15:10:00', '2026-02-26 10:00:00'),
('FIN60000403', 'DL07000003', (SELECT customer_id FROM sales_deal WHERE deal_number='DL07000003'), 'R', 'BMWFS', 'BMW Financial Services','FN', 52410.41, 52410.41, 5.500, 5.000, 72, 842.75, 22000.00, 'A', '2026-01-13 10:45:00', '2026-01-13 14:30:00', '2026-01-17 09:50:00'),
('FIN60000404', 'DL07000004', (SELECT customer_id FROM sales_deal WHERE deal_number='DL07000004'), 'L', 'BMWFS', 'BMW Financial Services','FN', 64410.41, 64410.41, 4.900, 4.500, 36, 1792.10, 10000.00, 'A', '2026-03-05 13:20:00', '2026-03-05 17:00:00', '2026-03-09 10:15:00'),
('FIN60000405', 'DL07000005', (SELECT customer_id FROM sales_deal WHERE deal_number='DL07000005'), 'L', 'BMWFS', 'BMW Financial Services','FN', 79906.41, 79906.41, 4.500, 4.250, 36, 2218.30, 15000.00, 'A', '2026-02-28 14:10:00', '2026-02-28 18:00:00', '2026-03-04 09:40:00'),
-- DLR03 Struggling — higher APR, B/C tier, some denials
('FIN60000501', 'DL03000101', (SELECT customer_id FROM sales_deal WHERE deal_number='DL03000101'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 28072.84, 28072.84, 8.250, 7.900, 72, 489.75, 4500.00,  'C', '2025-08-10 11:30:00', '2025-08-10 15:45:00', '2025-08-14 10:20:00'),
('FIN60000502', 'DL03000102', (SELECT customer_id FROM sales_deal WHERE deal_number='DL03000102'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 37043.39, 37043.39, 7.750, 7.500, 72, 643.20, 6000.00,  'B', '2025-10-25 10:20:00', '2025-10-25 14:00:00', '2025-10-30 10:30:00'),
('FIN60000503', 'DL03000103', (SELECT customer_id FROM sales_deal WHERE deal_number='DL03000103'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 33450.84, 33450.84, 7.500, 7.250, 72, 575.80, 5500.00,  'B', '2026-03-18 11:40:00', '2026-03-18 15:25:00', '2026-03-22 09:45:00'),
-- DLR08 Struggling #2 — similar pattern
('FIN60000601', 'DL08000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL08000001'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 29221.71, 29221.71, 8.500, 8.250, 72, 516.30, 3500.00,  'C', '2025-08-15 12:30:00', '2025-08-15 16:50:00', '2025-08-20 10:30:00'),
('FIN60000602', 'DL08000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL08000002'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','SB', 40000.00, NULL,     7.750, NULL,  NULL, NULL,  0.00,     NULL, '2026-04-12 14:20:00', NULL,                  NULL),
-- DLR04 Warranty hotspot — mid tier, normal rates
('FIN60000701', 'DL04000101', (SELECT customer_id FROM sales_deal WHERE deal_number='DL04000101'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 42113.58, 42113.58, 6.500, 6.250, 72, 708.90, 12000.00, 'B', '2025-11-20 10:40:00', '2025-11-20 14:20:00', '2025-11-25 09:30:00'),
('FIN60000702', 'DL04000102', (SELECT customer_id FROM sales_deal WHERE deal_number='DL04000102'), 'R', 'ALLY1', 'Ally Financial',        'FN', 40113.58, 40113.58, 6.250, 6.000, 60, 775.90, 14000.00, 'A', '2026-01-10 11:25:00', '2026-01-10 15:00:00', '2026-01-14 10:15:00'),
('FIN60000703', 'DL04000103', (SELECT customer_id FROM sales_deal WHERE deal_number='DL04000103'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 33202.08, 33202.08, 6.500, 6.250, 60, 647.85, 8000.00,  'B', '2026-02-18 14:50:00', '2026-02-18 18:30:00', '2026-02-22 10:00:00'),
('FIN60000704', 'DL04000104', (SELECT customer_id FROM sales_deal WHERE deal_number='DL04000104'), 'R', 'TDAFC', 'TD Auto Finance',       'FN', 31702.08, 31702.08, 6.750, 6.500, 72, 532.40, 9500.00,  'B', '2026-03-26 10:15:00', '2026-03-26 13:55:00', '2026-03-30 09:30:00'),
('FIN60000705', 'DL04000105', (SELECT customer_id FROM sales_deal WHERE deal_number='DL04000105'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 28053.73, 28053.73, 6.250, 6.000, 60, 542.70, 5000.00,  'A', '2026-04-03 11:00:00', '2026-04-03 14:40:00', '2026-04-07 09:45:00'),
('FIN60000706', 'DL04000106', (SELECT customer_id FROM sales_deal WHERE deal_number='DL04000106'), 'R', 'ALLY1', 'Ally Financial',        'NW', 28000.00, NULL,     6.500, NULL,  NULL, NULL,  0.00,     NULL, '2026-04-15 16:45:00', NULL,                  NULL),
-- DLR09 Warranty hotspot #2
('FIN60000801', 'DL09000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000001'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 40991.39, 40991.39, 6.500, 6.250, 72, 689.55, 12000.00, 'B', '2025-12-15 11:20:00', '2025-12-15 15:00:00', '2025-12-20 09:45:00'),
('FIN60000802', 'DL09000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000002'), 'R', 'ALLY1', 'Ally Financial',        'FN', 38991.39, 38991.39, 6.250, 5.900, 60, 753.20, 14000.00, 'A', '2026-01-22 10:30:00', '2026-01-22 14:10:00', '2026-01-26 09:50:00'),
('FIN60000803', 'DL09000003', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000003'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 41991.39, 41991.39, 6.750, 6.500, 72, 705.55, 11000.00, 'B', '2026-02-26 14:25:00', '2026-02-26 18:00:00', '2026-03-02 10:15:00'),
('FIN60000804', 'DL09000004', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000004'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 32228.64, 32228.64, 6.500, 6.250, 60, 628.90, 8000.00,  'B', '2026-01-12 09:50:00', '2026-01-12 13:30:00', '2026-01-16 10:00:00'),
('FIN60000805', 'DL09000005', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000005'), 'R', 'ALLY1', 'Ally Financial',        'FN', 30228.64, 30228.64, 6.250, 6.000, 60, 584.45, 10000.00, 'A', '2026-02-18 11:40:00', '2026-02-18 15:20:00', '2026-02-22 10:15:00'),
('FIN60000806', 'DL09000006', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000006'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 31228.64, 31228.64, 6.750, 6.500, 72, 524.60, 9000.00,  'B', '2026-03-28 10:45:00', '2026-03-28 14:25:00', '2026-04-01 09:30:00'),
('FIN60000807', 'DL09000007', (SELECT customer_id FROM sales_deal WHERE deal_number='DL09000007'), 'R', 'CHASE', 'Chase Auto Finance',    'SB', 28000.00, NULL,     6.500, NULL,  NULL, NULL,  0.00,     NULL, '2026-04-14 15:30:00', NULL,                  NULL),
-- DLR05 F&I powerhouse — BMW, excellent tiers, highest F&I attach
('FIN60000901', 'DL05000101', (SELECT customer_id FROM sales_deal WHERE deal_number='DL05000101'), 'L', 'BMWFS', 'BMW Financial Services','FN', 43148.58, 43148.58, 4.900, 4.500, 36, 1201.50, 8000.00,  'A', '2025-12-18 11:30:00', '2025-12-18 15:10:00', '2025-12-22 10:00:00'),
('FIN60000902', 'DL05000102', (SELECT customer_id FROM sales_deal WHERE deal_number='DL05000102'), 'L', 'BMWFS', 'BMW Financial Services','FN', 41648.58, 41648.58, 4.750, 4.250, 36, 1158.10, 9500.00,  'A', '2026-03-02 10:20:00', '2026-03-02 13:55:00', '2026-03-06 09:45:00'),
('FIN60000903', 'DL05000103', (SELECT customer_id FROM sales_deal WHERE deal_number='DL05000103'), 'L', 'BMWFS', 'BMW Financial Services','FN', 59013.83, 59013.83, 4.500, 4.000, 36, 1642.50, 15000.00, 'A', '2026-01-22 13:45:00', '2026-01-22 17:30:00', '2026-01-26 10:30:00'),
('FIN60000904', 'DL05000104', (SELECT customer_id FROM sales_deal WHERE deal_number='DL05000104'), 'L', 'BMWFS', 'BMW Financial Services','FN', 56013.83, 56013.83, 4.500, 4.100, 36, 1559.00, 18000.00, 'A', '2026-03-18 11:50:00', '2026-03-18 15:35:00', '2026-03-22 10:20:00'),
('FIN60000905', 'DL05000105', (SELECT customer_id FROM sales_deal WHERE deal_number='DL05000105'), 'L', 'BMWFS', 'BMW Financial Services','FN', 74433.03, 74433.03, 4.250, 3.900, 36, 2067.60, 20000.00, 'A', '2026-04-01 10:10:00', '2026-04-01 13:45:00', '2026-04-05 09:40:00'),
('FIN60000906', 'DL05000106', (SELECT customer_id FROM sales_deal WHERE deal_number='DL05000106'), 'L', 'BMWFS', 'BMW Financial Services','FN', 72433.03, 72433.03, 4.250, 3.750, 36, 2013.10, 22000.00, 'A', '2026-04-14 11:30:00', '2026-04-14 15:10:00', '2026-04-16 10:00:00'),
-- DLR10 F&I powerhouse #2 — Toyota, high F&I attach
('FIN60001001', 'DL10000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000001'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 28192.30, 28192.30, 6.250, 5.900, 60, 544.90, 5000.00,  'A', '2026-01-08 10:20:00', '2026-01-08 14:00:00', '2026-01-12 09:30:00'),
('FIN60001002', 'DL10000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000002'), 'R', 'ALLY1', 'Ally Financial',        'FN', 27567.65, 27567.65, 6.000, 5.750, 60, 531.20, 6500.00,  'A', '2026-02-20 11:15:00', '2026-02-20 14:50:00', '2026-02-24 10:00:00'),
('FIN60001003', 'DL10000003', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000003'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 26067.65, 26067.65, 6.250, 5.900, 60, 503.90, 8000.00,  'A', '2026-03-30 10:40:00', '2026-03-30 14:20:00', '2026-04-03 09:45:00'),
('FIN60001004', 'DL10000004', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000004'), 'R', 'ALLY1', 'Ally Financial',        'FN', 34051.90, 34051.90, 6.500, 6.250, 72, 571.30, 8000.00,  'B', '2026-01-18 11:00:00', '2026-01-18 14:40:00', '2026-01-22 09:50:00'),
('FIN60001005', 'DL10000005', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000005'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 32551.90, 32551.90, 6.250, 6.000, 60, 629.30, 9500.00,  'A', '2026-02-25 10:50:00', '2026-02-25 14:30:00', '2026-03-01 09:40:00'),
('FIN60001006', 'DL10000006', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000006'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 34746.95, 34746.95, 6.750, 6.500, 72, 583.85, 7000.00,  'B', '2026-02-12 11:20:00', '2026-02-12 15:00:00', '2026-02-16 10:10:00'),
('FIN60001007', 'DL10000007', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000007'), 'R', 'ALLY1', 'Ally Financial',        'FN', 33246.95, 33246.95, 6.500, 6.250, 72, 557.40, 8500.00,  'B', '2026-03-22 10:30:00', '2026-03-22 14:15:00', '2026-03-26 09:50:00'),
('FIN60001008', 'DL10000008', (SELECT customer_id FROM sales_deal WHERE deal_number='DL10000008'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 39450.95, 39450.95, 6.750, 6.500, 72, 662.80, 10000.00, 'B', '2026-01-23 11:50:00', '2026-01-23 15:30:00', '2026-01-27 10:00:00'),
-- DLR11 Baseline
('FIN60001101', 'DL11000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL11000001'), 'R', 'ALLY1', 'Ally Financial',        'FN', 40009.51, 40009.51, 6.250, 6.000, 72, 671.20, 10000.00, 'B', '2026-02-22 10:30:00', '2026-02-22 14:05:00', '2026-02-26 09:30:00'),
('FIN60001102', 'DL11000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL11000002'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 34541.67, 34541.67, 6.500, 6.250, 60, 673.40, 6000.00,  'B', '2025-12-15 11:45:00', '2025-12-15 15:25:00', '2025-12-20 10:00:00'),
('FIN60001103', 'DL11000003', (SELECT customer_id FROM sales_deal WHERE deal_number='DL11000003'), 'R', 'ALLY1', 'Ally Financial',        'FN', 33041.67, 33041.67, 6.250, 5.900, 60, 639.20, 7500.00,  'A', '2026-03-30 10:10:00', '2026-03-30 13:45:00', '2026-04-03 09:45:00'),
('FIN60001104', 'DL11000004', (SELECT customer_id FROM sales_deal WHERE deal_number='DL11000004'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 36764.02, 36764.02, 6.750, 6.500, 72, 617.80, 12000.00, 'B', '2026-03-15 11:30:00', '2026-03-15 15:10:00', '2026-03-19 09:30:00'),
('FIN60001105', 'DL11000005', (SELECT customer_id FROM sales_deal WHERE deal_number='DL11000005'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 43442.95, 43442.95, 6.500, 6.250, 72, 731.10, 15000.00, 'B', '2026-02-28 10:50:00', '2026-02-28 14:30:00', '2026-03-04 09:40:00'),
-- DLR12 Baseline
('FIN60001201', 'DL12000001', (SELECT customer_id FROM sales_deal WHERE deal_number='DL12000001'), 'R', 'CHASE', 'Chase Auto Finance',    'FN', 36616.87, 36616.87, 6.500, 6.250, 72, 615.30, 7000.00,  'B', '2026-02-02 10:40:00', '2026-02-02 14:20:00', '2026-02-06 09:50:00'),
('FIN60001202', 'DL12000002', (SELECT customer_id FROM sales_deal WHERE deal_number='DL12000002'), 'R', 'ALLY1', 'Ally Financial',        'FN', 27910.91, 27910.91, 6.250, 6.000, 60, 538.70, 5000.00,  'B', '2025-12-28 11:15:00', '2025-12-28 14:55:00', '2026-01-02 10:00:00'),
('FIN60001203', 'DL12000003', (SELECT customer_id FROM sales_deal WHERE deal_number='DL12000003'), 'R', 'CPTL1', 'Capital One Auto',      'FN', 31431.91, 31431.91, 6.500, 6.250, 60, 612.90, 8000.00,  'A', '2026-03-10 10:20:00', '2026-03-10 14:00:00', '2026-03-14 09:30:00'),
('FIN60001204', 'DL12000004', (SELECT customer_id FROM sales_deal WHERE deal_number='DL12000004'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','FN', 39932.41, 39932.41, 6.750, 6.500, 72, 670.95, 12000.00, 'B', '2026-04-06 11:00:00', '2026-04-06 14:40:00', '2026-04-10 10:15:00');

-- ── Credit Checks (45 — mixed bureaus, persona-aware score distribution) ─
INSERT INTO credit_check (customer_id, bureau_code, credit_score, credit_tier, request_ts, response_ts, status, monthly_debt, monthly_income, dti_ratio, expiry_date) VALUES
-- DLR01 volume (mostly good tier)
(1,  'EX', 745, 'A', '2025-11-14 09:30:00', '2025-11-14 09:32:15', 'CP', 1850.00, 7666.67,  24.13, '2025-12-14'),
(2,  'TU', 721, 'A', '2025-12-21 10:15:00', '2025-12-21 10:17:30', 'CP', 2100.00, 6500.00,  32.31, '2026-01-20'),
(3,  'EQ', 698, 'B', '2026-02-09 11:20:00', '2026-02-09 11:22:45', 'CP', 1650.00, 9583.33,  17.22, '2026-03-11'),
-- DLR02 luxury (all A tier)
(7,  'EX', 780, 'A', '2025-12-21 14:30:00', '2025-12-21 14:32:00', 'CP', 2400.00, 10416.67, 23.04, '2026-01-20'),
(9,  'TU', 765, 'A', '2026-03-12 10:45:00', '2026-03-12 10:47:20', 'CP', 1800.00, 8750.00,  20.57, '2026-04-11'),
-- DLR03 struggling (more C/D)
(13, 'EX', 645, 'C', '2025-08-09 12:30:00', '2025-08-09 12:33:10', 'CP', 1950.00, 6833.33,  28.54, '2025-09-08'),
(14, 'TU', 612, 'C', '2025-10-24 13:15:00', '2025-10-24 13:17:30', 'CP', 2250.00, 5166.67,  43.55, '2025-11-23'),
(15, 'EQ', 680, 'B', '2026-03-17 14:20:00', '2026-03-17 14:22:45', 'CP', 1720.00, 7916.67,  21.73, '2026-04-16'),
(16, 'EX', 595, 'D', '2026-02-28 11:10:00', '2026-02-28 11:12:30', 'CP', 1400.00, 3583.33,  39.07, '2026-03-30'),
-- DLR04 warranty hotspot (mixed)
(19, 'EX', 718, 'A', '2025-11-19 10:40:00', '2025-11-19 10:42:15', 'CP', 1950.00, 7250.00,  26.90, '2025-12-19'),
(20, 'TU', 702, 'B', '2026-01-09 11:25:00', '2026-01-09 11:27:40', 'CP', 1680.00, 6333.33,  26.53, '2026-02-08'),
(21, 'EQ', 655, 'C', '2026-02-17 14:50:00', '2026-02-17 14:53:15', 'CP', 2400.00, 10000.00, 24.00, '2026-03-19'),
-- DLR05 luxury (all A)
(25, 'EX', 810, 'A', '2025-12-17 11:30:00', '2025-12-17 11:31:50', 'CP', 3200.00, 20833.33, 15.36, '2026-01-16'),
(26, 'TU', 795, 'A', '2026-03-01 10:20:00', '2026-03-01 10:22:10', 'CP', 2850.00, 15416.67, 18.49, '2026-03-31'),
(27, 'EQ', 825, 'A', '2026-01-21 13:45:00', '2026-01-21 13:47:30', 'CP', 4100.00, 26666.67, 15.37, '2026-02-20'),
(28, 'EX', 788, 'A', '2026-03-17 11:50:00', '2026-03-17 11:52:20', 'CP', 2200.00, 7916.67,  27.79, '2026-04-16'),
-- DLR06 volume (mixed good)
((SELECT customer_id FROM customer WHERE email='kdonovan@email.com'),   'EX', 735, 'A', '2026-01-08 11:20:00', '2026-01-08 11:22:30', 'CP', 1900.00, 7416.67,  25.62, '2026-02-07'),
((SELECT customer_id FROM customer WHERE email='astapleton@email.com'), 'TU', 712, 'B', '2026-03-15 10:30:00', '2026-03-15 10:32:40', 'CP', 1800.00, 6833.33,  26.34, '2026-04-14'),
((SELECT customer_id FROM customer WHERE email='lokonkwo@email.com'),   'EQ', 758, 'A', '2026-01-27 14:15:00', '2026-01-27 14:17:20', 'CP', 2500.00, 9333.33,  26.79, '2026-02-26'),
((SELECT customer_id FROM customer WHERE email='pnolan@email.com'),     'EX', 685, 'B', '2026-02-19 09:45:00', '2026-02-19 09:47:15', 'CP', 1620.00, 6083.33,  26.63, '2026-03-21'),
-- DLR07 luxury BMW (all top tier)
((SELECT customer_id FROM customer WHERE email='rprescott@email.com'),  'EX', 828, 'A', '2025-12-19 14:00:00', '2025-12-19 14:01:50', 'CP', 3800.00, 17500.00, 21.71, '2026-01-18'),
((SELECT customer_id FROM customer WHERE email='cferguson@email.com'),  'TU', 798, 'A', '2026-02-21 11:30:00', '2026-02-21 11:32:15', 'CP', 2800.00, 12916.67, 21.68, '2026-03-23'),
((SELECT customer_id FROM customer WHERE email='bhayes@email.com'),     'EQ', 842, 'A', '2026-01-12 10:45:00', '2026-01-12 10:46:30', 'CP', 4500.00, 22916.67, 19.64, '2026-02-11'),
((SELECT customer_id FROM customer WHERE email='matherton@email.com'),  'EX', 815, 'A', '2026-04-21 09:30:00', '2026-04-21 09:31:40', 'CP', 3900.00, 26666.67, 14.63, '2026-05-21'),
-- DLR08 struggling (C/D heavy)
((SELECT customer_id FROM customer WHERE email='tvaladez@email.com'),   'EX', 620, 'C', '2025-08-14 12:30:00', '2025-08-14 12:33:00', 'CP', 1750.00, 5166.67,  33.87, '2025-09-13'),
((SELECT customer_id FROM customer WHERE email='drasmussen@email.com'), 'TU', 585, 'D', '2026-04-11 13:15:00', '2026-04-11 13:17:40', 'DN', 2100.00, 4833.33,  43.45, '2026-05-11'),
((SELECT customer_id FROM customer WHERE email='jpeacock@email.com'),   'EQ', 598, 'D', '2026-04-01 14:20:00', '2026-04-01 14:22:50', 'CP', 1350.00, 3250.00,  41.54, '2026-05-01'),
((SELECT customer_id FROM customer WHERE email='ralcantar@email.com'),  'EX', 668, 'B', '2026-03-09 11:40:00', '2026-03-09 11:42:20', 'CP', 1900.00, 5916.67,  32.11, '2026-04-08'),
-- DLR09 warranty hotspot (mixed)
((SELECT customer_id FROM customer WHERE email='gthibodaux@email.com'), 'EX', 720, 'A', '2025-12-14 10:40:00', '2025-12-14 10:42:10', 'CP', 2100.00, 7666.67,  27.39, '2026-01-13'),
((SELECT customer_id FROM customer WHERE email='mspellman@email.com'),  'TU', 735, 'A', '2026-01-21 11:15:00', '2026-01-21 11:17:35', 'CP', 1850.00, 7333.33,  25.23, '2026-02-20'),
((SELECT customer_id FROM customer WHERE email='cpendergrass@email.com'),'EQ', 775, 'A', '2026-02-25 13:30:00', '2026-02-25 13:31:40', 'CP', 3200.00, 15416.67, 20.76, '2026-03-27'),
((SELECT customer_id FROM customer WHERE email='wambrose@email.com'),   'EX', 702, 'B', '2026-04-17 10:50:00', '2026-04-17 10:52:30', 'CP', 1600.00, 6333.33,  25.26, '2026-05-17'),
-- DLR10 F&I (all good tiers)
((SELECT customer_id FROM customer WHERE email='tbancroft@email.com'),  'EX', 755, 'A', '2026-01-07 10:20:00', '2026-01-07 10:22:10', 'CP', 2400.00, 8750.00,  27.43, '2026-02-06'),
((SELECT customer_id FROM customer WHERE email='mengstrom@email.com'),  'TU', 768, 'A', '2026-02-19 11:15:00', '2026-02-19 11:17:00', 'CP', 2100.00, 7833.33,  26.81, '2026-03-21'),
((SELECT customer_id FROM customer WHERE email='bkirkpatrick@email.com'),'EQ', 790, 'A', '2026-01-25 14:40:00', '2026-01-25 14:41:50', 'CP', 2800.00, 12083.33, 23.17, '2026-02-24'),
((SELECT customer_id FROM customer WHERE email='aredmond@email.com'),   'EX', 725, 'A', '2026-03-25 10:10:00', '2026-03-25 10:12:15', 'CP', 1800.00, 6833.33,  26.34, '2026-04-24'),
((SELECT customer_id FROM customer WHERE email='cfairchild@email.com'), 'TU', 742, 'A', '2026-04-22 09:30:00', '2026-04-22 09:32:00', 'CP', 2600.00, 9583.33,  27.13, '2026-05-22'),
-- DLR11 baseline
((SELECT customer_id FROM customer WHERE email='hvanderberg@email.com'),'EX', 715, 'A', '2026-02-21 11:20:00', '2026-02-21 11:22:00', 'CP', 1950.00, 8000.00,  24.38, '2026-03-23'),
((SELECT customer_id FROM customer WHERE email='bsorensen@email.com'),  'TU', 695, 'B', '2025-12-14 10:25:00', '2025-12-14 10:27:30', 'CP', 1600.00, 6166.67,  25.95, '2026-01-13'),
((SELECT customer_id FROM customer WHERE email='rbouchard@email.com'),  'EQ', 748, 'A', '2026-04-19 11:40:00', '2026-04-19 11:42:15', 'CP', 2200.00, 8750.00,  25.14, '2026-05-19'),
-- DLR12 baseline
((SELECT customer_id FROM customer WHERE email='dmcnamara@email.com'),  'EX', 722, 'A', '2026-02-01 10:30:00', '2026-02-01 10:32:10', 'CP', 1850.00, 7416.67,  24.94, '2026-03-03'),
((SELECT customer_id FROM customer WHERE email='abrockway@email.com'),  'TU', 688, 'B', '2025-12-27 11:10:00', '2025-12-27 11:12:30', 'CP', 1700.00, 6000.00,  28.33, '2026-01-26'),
((SELECT customer_id FROM customer WHERE email='ksumner@email.com'),    'EQ', 738, 'A', '2026-04-09 10:45:00', '2026-04-09 10:47:20', 'CP', 2000.00, 8000.00,  25.00, '2026-05-09'),
((SELECT customer_id FROM customer WHERE email='sgreenlee@email.com'),  'EX', 782, 'A', '2026-04-18 09:50:00', '2026-04-18 09:51:40', 'CP', 3100.00, 11166.67, 27.76, '2026-05-18');
