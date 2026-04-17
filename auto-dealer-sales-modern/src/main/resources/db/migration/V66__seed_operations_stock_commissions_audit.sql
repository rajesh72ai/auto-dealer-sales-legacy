-- ==========================================================================
-- V66: Operations data — stock positions (new dealers), transfers,
-- adjustments, commissions, audit log, daily/monthly rollups.
-- Final migration in the V60-V66 AI-demo seed enrichment set.
-- ==========================================================================

-- ── Stock positions for new dealers (DLR06-DLR12) ──────────────────
-- Hand-computed from V60 + V61 supplemental vehicle counts, net of V61
-- delivered deals (vehicle status transitioned AV→SD in V61 UPDATE).
INSERT INTO stock_position (dealer_code, model_year, make_code, model_code, on_hand_count, in_transit_count, allocated_count, on_hold_count, sold_mtd, sold_ytd, reorder_point) VALUES
-- DLR06 Plainfield Ford
('DLR06', 2025, 'FRD', 'F150XL', 0, 0, 0, 0, 0,  2, 3),
('DLR06', 2026, 'FRD', 'F150XL', 1, 1, 0, 0, 2,  3, 3),
('DLR06', 2025, 'FRD', 'ESCSEL', 0, 0, 0, 0, 1,  3, 2),
('DLR06', 2025, 'FRD', 'MUSTGT', 0, 0, 0, 0, 0,  2, 2),
('DLR06', 2026, 'FRD', 'EXPLLT', 1, 0, 1, 0, 1,  2, 2),
-- DLR07 Charlotte BMW
('DLR07', 2025, 'BMW', '330IXD', 2, 0, 0, 0, 0,  2, 2),
('DLR07', 2025, 'BMW', 'X5XD40', 2, 0, 0, 0, 2,  3, 2),
('DLR07', 2026, 'BMW', 'IX_50E', 1, 0, 0, 0, 1,  2, 1),
-- DLR08 Riverside Honda (struggling — lots of aged stock remaining)
('DLR08', 2025, 'HND', 'CIVICX', 4, 0, 0, 0, 1,  1, 3),
('DLR08', 2025, 'HND', 'CRV_EL', 4, 0, 0, 0, 0,  0, 3),
('DLR08', 2026, 'HND', 'ACCORD', 2, 0, 0, 0, 0,  0, 2),
('DLR08', 2025, 'HND', 'PILTEX', 2, 0, 0, 0, 0,  0, 2),
-- DLR09 Dallas Chevrolet
('DLR09', 2025, 'CHV', 'SILVLT', 2, 0, 0, 0, 1,  4, 3),
('DLR09', 2026, 'CHV', 'EQNOLT', 0, 0, 0, 0, 3,  3, 3),
('DLR09', 2025, 'CHV', 'MALIBU', 2, 0, 0, 0, 0,  0, 2),
-- DLR10 Boise Toyota
('DLR10', 2025, 'TYT', 'CAMRYL', 0, 0, 0, 0, 1,  1, 2),
('DLR10', 2026, 'TYT', 'CAMRYL', 0, 0, 0, 0, 2,  2, 2),
('DLR10', 2025, 'TYT', 'RAV4XP', 0, 1, 0, 0, 2,  2, 2),
('DLR10', 2025, 'TYT', 'TACSR5', 0, 0, 0, 0, 2,  2, 2),
('DLR10', 2025, 'TYT', 'HGHLXL', 1, 0, 0, 0, 1,  1, 2),
-- DLR11 Madison Ford (baseline)
('DLR11', 2025, 'FRD', 'F150XL', 1, 0, 0, 0, 1,  1, 2),
('DLR11', 2026, 'FRD', 'F150XL', 0, 0, 0, 0, 0,  0, 2),
('DLR11', 2025, 'FRD', 'ESCSEL', 0, 0, 0, 0, 2,  2, 2),
('DLR11', 2025, 'FRD', 'MUSTGT', 0, 0, 0, 0, 1,  1, 1),
('DLR11', 2026, 'FRD', 'EXPLLT', 0, 1, 0, 0, 1,  1, 1),
-- DLR12 Albany Honda (baseline)
('DLR12', 2025, 'HND', 'CIVICX', 2, 0, 0, 0, 0,  0, 2),
('DLR12', 2025, 'HND', 'CRV_EL', 1, 0, 0, 0, 1,  1, 2),
('DLR12', 2026, 'HND', 'ACCORD', 2, 0, 0, 0, 0,  0, 2),
('DLR12', 2025, 'HND', 'PILTEX', 0, 1, 0, 0, 1,  1, 1);

-- Refresh stock_position sold_mtd/sold_ytd for existing dealers
-- (V26 had pre-computed values; V61 added more DL deals — update counts)
UPDATE stock_position SET sold_mtd = 2, sold_ytd = 8, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR01' AND model_code = 'F150XL';
UPDATE stock_position SET sold_mtd = 1, sold_ytd = 6, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR01' AND model_code = 'ESCSEL';
UPDATE stock_position SET sold_mtd = 2, sold_ytd = 4, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR01' AND model_code = 'EXPLLT';
UPDATE stock_position SET sold_mtd = 1, sold_ytd = 3, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR02' AND model_code = 'HGHLXL';
UPDATE stock_position SET sold_mtd = 0, sold_ytd = 2, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR03' AND model_code = 'CIVICX';
UPDATE stock_position SET sold_mtd = 1, sold_ytd = 3, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR04' AND model_code = 'SILVLT';
UPDATE stock_position SET sold_mtd = 2, sold_ytd = 4, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR04' AND model_code = 'EQNOLT';
UPDATE stock_position SET sold_mtd = 2, sold_ytd = 6, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR05' AND model_code = 'X5XD40';
UPDATE stock_position SET sold_mtd = 1, sold_ytd = 3, updated_ts = CURRENT_TIMESTAMP WHERE dealer_code = 'DLR05' AND model_code = 'IX_50E';

-- ── Stock Transfers (6 inter-dealer transfers) ──────────────────────
INSERT INTO stock_transfer (from_dealer, to_dealer, vin, transfer_status, requested_by, approved_by, requested_ts, approved_ts, completed_ts) VALUES
('DLR06', 'DLR01', '1FTFW1E53PFA06006', 'RQ', 'ARUSSO06', NULL,       '2026-04-10 11:20:00', NULL,                  NULL),
('DLR08', 'DLR12', '7FARW2H93NE608003', 'CM', 'DFERNA08', 'MRODRI12', '2026-03-12 09:45:00', '2026-03-12 14:20:00', '2026-03-20 10:15:00'),
('DLR09', 'DLR04', '1GCUYEED5NZ909003', 'AP', 'CBENNT09', 'WCLARK04', '2026-04-05 13:10:00', '2026-04-05 16:30:00', NULL),
('DLR01', 'DLR11', '1FM5K8GC7PGA01502', 'CM', 'JPATTER1', 'GANDER11', '2026-04-08 10:30:00', '2026-04-08 13:45:00', '2026-04-15 09:50:00'),
('DLR07', 'DLR05', 'WBA5R1C50NFJ07003', 'RJ', 'VPRICE07', 'EHART005', '2026-02-20 14:20:00', '2026-02-21 09:10:00', NULL),
('DLR10', 'DLR02', '2T3WFREV5NW201003', 'RQ', 'RLARSE10', NULL,       '2026-04-12 11:45:00', NULL,                  NULL);

-- ── Stock Adjustments (6) ────────────────────────────────────────────
INSERT INTO stock_adjustment (dealer_code, vin, adjust_type, adjust_reason, old_status, new_status, adjusted_by, adjusted_ts) VALUES
('DLR03', '19XFC1F38NE503001', 'DM', 'Minor lot damage discovered during PDI; moved to hold for repair estimate', 'AV', 'HD', 'RNGUYEN3', '2026-04-10 14:30:00'),
('DLR08', '19XFC1F38NE508001', 'AG', 'Aged inventory over 180 days; marked for aggressive pricing strategy',       'AV', 'AV', 'DFERNA08', '2026-04-12 10:15:00'),
('DLR04', '1GCUYEED5NZ900101', 'RC', 'Active recall RCL2026002 — on-hold until EPS software update complete',     'AV', 'HD', 'WCLARK04', '2026-03-26 09:20:00'),
('DLR09', '3GNAXKEV0PS109003', 'RC', 'Active recall RCL2026001 — battery inspection required',                    'AV', 'HD', 'CBENNT09', '2026-04-01 11:40:00'),
('DLR06', '1FTFW1E53PFA06005', 'HD', 'Customer put down deposit; vehicle reserved pending finance approval',       'AV', 'HD', 'JSMITH06', '2026-04-14 16:10:00'),
('DLR01', '1FM5K8GC7PGA01502', 'TR', 'Transfer to DLR11 approved; will ship this week',                            'AV', 'HD', 'JPATTER1', '2026-04-08 13:50:00');

-- ── Commissions (40 entries for delivered deals) ────────────────────
-- comm_type: ST=Standard, SR=Senior, MG=Manager override, BO=Bonus
INSERT INTO commission (dealer_code, salesperson_id, deal_number, comm_type, gross_amount, comm_rate, comm_amount, pay_period, paid_flag) VALUES
-- DLR01 volume
('DLR01', 'TSMITH01', 'DL01000101', 'ST', 3398.50,  0.2500, 849.63,  '202511', 'Y'),
('DLR01', 'TSMITH01', 'DL01000102', 'ST', 4023.00,  0.2500, 1005.75, '202512', 'Y'),
('DLR01', 'JDOE0001', 'DL01000103', 'ST', 3975.00,  0.2500, 993.75,  '202602', 'Y'),
('DLR01', 'TSMITH01', 'DL01000104', 'ST', 4237.50,  0.2500, 1059.38, '202603', 'Y'),
('DLR01', 'TSMITH01', 'DL01000108', 'ST', 4552.60,  0.2500, 1138.15, '202603', 'Y'),
('DLR01', 'JDOE0001', 'DL01000109', 'ST', 4677.60,  0.2500, 1169.40, '202604', 'N'),
-- DLR06 volume #2
('DLR06', 'JSMITH06', 'DL06000001', 'SR', 2770.00,  0.3000, 831.00,  '202601', 'Y'),
('DLR06', 'TBROWN06', 'DL06000002', 'ST', 3845.40,  0.2500, 961.35,  '202603', 'Y'),
('DLR06', 'JSMITH06', 'DL06000003', 'SR', 3573.35,  0.3000, 1072.01, '202601', 'Y'),
('DLR06', 'TBROWN06', 'DL06000004', 'ST', 4023.00,  0.2500, 1005.75, '202602', 'Y'),
('DLR06', 'JSMITH06', 'DL06000005', 'SR', 3925.00,  0.3000, 1177.50, '202603', 'Y'),
('DLR06', 'TBROWN06', 'DL06000006', 'ST', 4175.00,  0.2500, 1043.75, '202604', 'N'),
('DLR06', 'TBROWN06', 'DL06000008', 'ST', 4452.60,  0.2500, 1113.15, '202603', 'Y'),
-- DLR02 luxury
('DLR02', 'DJONES02', 'DL02000101', 'SR', 5836.10,  0.3500, 2042.64, '202512', 'Y'),
('DLR02', 'APARK002', 'DL02000102', 'ST', 6263.25,  0.2500, 1565.81, '202603', 'Y'),
('DLR02', 'DJONES02', 'DL02000103', 'SR', 6878.50,  0.3500, 2407.48, '202604', 'N'),
-- DLR07 luxury BMW
('DLR07', 'DGOLD07',  'DL07000001', 'SR', 7522.00,  0.3500, 2632.70, '202512', 'Y'),
('DLR07', 'CGREY07',  'DL07000002', 'SR', 7954.00,  0.3500, 2783.90, '202602', 'Y'),
('DLR07', 'DGOLD07',  'DL07000003', 'SR', 11219.00, 0.3500, 3926.65, '202601', 'Y'),
('DLR07', 'CGREY07',  'DL07000004', 'SR', 12348.00, 0.3500, 4321.80, '202603', 'Y'),
('DLR07', 'DGOLD07',  'DL07000005', 'SR', 16423.00, 0.3500, 5748.05, '202603', 'Y'),
-- DLR03 struggling (low commissions)
('DLR03', 'KLEE0003', 'DL03000101', 'ST', 1193.50,  0.2000, 238.70,  '202508', 'Y'),
('DLR03', 'LWONG003', 'DL03000102', 'ST', 2029.00,  0.2000, 405.80,  '202510', 'Y'),
('DLR03', 'KLEE0003', 'DL03000103', 'ST', 1470.50,  0.2000, 294.10,  '202603', 'Y'),
-- DLR08 struggling
('DLR08', 'KSANT08',  'DL08000001', 'ST', 1008.75,  0.2000, 201.75,  '202508', 'Y'),
-- DLR04 warranty
('DLR04', 'MBROWN04', 'DL04000101', 'SR', 3615.00,  0.2750, 994.13,  '202511', 'Y'),
('DLR04', 'RGREEN04', 'DL04000102', 'ST', 4213.00,  0.2500, 1053.25, '202601', 'Y'),
('DLR04', 'MBROWN04', 'DL04000103', 'SR', 2845.00,  0.2750, 782.38,  '202602', 'Y'),
('DLR04', 'RGREEN04', 'DL04000104', 'ST', 3379.00,  0.2500, 844.75,  '202603', 'Y'),
-- DLR09 warranty #2
('DLR09', 'MJOHN09',  'DL09000001', 'SR', 3665.00,  0.2750, 1007.88, '202512', 'Y'),
('DLR09', 'BFOSTER9', 'DL09000002', 'ST', 4263.00,  0.2500, 1065.75, '202601', 'Y'),
('DLR09', 'MJOHN09',  'DL09000003', 'SR', 3540.00,  0.2750, 973.50,  '202602', 'Y'),
-- DLR05 F&I (commissions include F&I back-end — high amounts)
('DLR05', 'PCHEN005', 'DL05000101', 'SR', 7098.00,  0.3500, 2484.30, '202512', 'Y'),
('DLR05', 'SLEE0005', 'DL05000102', 'SR', 7605.00,  0.3500, 2661.75, '202603', 'Y'),
('DLR05', 'PCHEN005', 'DL05000103', 'SR', 9878.00,  0.3500, 3457.30, '202601', 'Y'),
('DLR05', 'SLEE0005', 'DL05000104', 'SR', 10542.50, 0.3500, 3689.88, '202603', 'Y'),
('DLR05', 'PCHEN005', 'DL05000105', 'SR', 13332.50, 0.3500, 4666.38, '202604', 'N'),
('DLR05', 'SLEE0005', 'DL05000106', 'SR', 15090.00, 0.3500, 5281.50, '202604', 'N'),
-- DLR10 F&I #2
('DLR10', 'SMART10',  'DL10000001', 'SR', 4219.70,  0.3500, 1476.90, '202601', 'Y'),
('DLR10', 'EYOUNG10', 'DL10000002', 'ST', 4743.75,  0.2500, 1185.94, '202602', 'Y'),
('DLR10', 'SMART10',  'DL10000004', 'SR', 5402.10,  0.3500, 1890.74, '202601', 'Y'),
('DLR10', 'SMART10',  'DL10000005', 'SR', 5952.45,  0.3500, 2083.36, '202602', 'Y'),
('DLR10', 'EYOUNG10', 'DL10000008', 'ST', 6650.30,  0.2500, 1662.58, '202601', 'Y');

-- ── Commission audit entries (6) ─────────────────────────────────────
INSERT INTO commission_audit (deal_number, entity_type, description) VALUES
('DL07000005', 'COMMIS', 'High-value EV commission reviewed; senior rate applied per policy CP-SR-01'),
('DL05000106', 'COMMIS', 'Back-end gross exceeds $7K threshold; bonus tier evaluated'),
('DL06000009', 'DEAL',   'Conditional approval — commission pending funding'),
('DL01000110', 'DEAL',   'Working deal — no commission calculation yet'),
('DL03000102', 'COMMIS', 'Low gross flagged for sales manager review; rate confirmed at standard'),
('DL10000005', 'COMMIS', 'Senior rate applied; F&I back-end contributed 56% of total gross');

-- ── Audit Log (40 entries across last 30 days) ──────────────────────
INSERT INTO audit_log (user_id, program_id, action_type, table_name, key_value, old_value, new_value, audit_ts) VALUES
-- Recent activity (April 2026, last 15 days heavy)
('TSMITH01', 'SDCRT001', 'INS', 'sales_deal',      'DL01000110', NULL,                                'status=WS, amount_financed=0.00',                  '2026-04-15 14:22:10'),
('SLEE0005', 'SDCRT001', 'INS', 'sales_deal',      'DL05000106', NULL,                                'status=DL, total_gross=15090.00',                  '2026-04-14 11:30:45'),
('TBROWN06', 'SDCRT001', 'INS', 'sales_deal',      'DL06000007', NULL,                                'status=WS, vehicle_price=46250.00',                '2026-04-14 15:42:18'),
('CBENNT09', 'WCMUPD01', 'UPD', 'warranty_claim',  'CL600015',   'status=NW',                         'status=PA',                                        '2026-04-14 10:15:33'),
('PCHEN005', 'SDCRT001', 'INS', 'sales_deal',      'DL05000105', NULL,                                'status=DL, total_gross=13332.50',                  '2026-04-01 10:10:05'),
('RGREEN04', 'WCMUPD01', 'UPD', 'warranty_claim',  'CL600008',   NULL,                                'status=NW, total_claim=630.00',                    '2026-04-08 13:45:22'),
('JPATTER1', 'STADJ001', 'UPD', 'stock_adjustment','458',        'old_status=AV',                     'new_status=HD (transfer pending)',                 '2026-04-08 13:50:10'),
('ARUSSO06', 'STADJ001', 'INS', 'stock_transfer',  '7',          NULL,                                'from=DLR06, to=DLR01, status=RQ',                  '2026-04-10 11:20:14'),
('GANDER11', 'STADJ001', 'UPD', 'stock_transfer',  '10',         'status=AP',                         'status=CM',                                        '2026-04-15 09:52:30'),
('SYSADMIN', 'BATPAY01', 'RUN', 'batch_control',   'COMMCALC',   'last_run=2026-04-07',               'last_run=2026-04-14, records=42',                  '2026-04-14 02:30:00'),
('SYSADMIN', 'BATREP01', 'RUN', 'batch_control',   'DAILYRPT',   'last_run=2026-04-14',               'last_run=2026-04-15, records=8',                   '2026-04-15 01:15:00'),
('DGOLD07',  'LEADUP01', 'UPD', 'customer_lead',   '45',         'status=QF',                         'status=WN',                                        '2026-04-14 14:22:08'),
('JSMITH06', 'CUSTCRT',  'INS', 'customer',        '71',         NULL,                                'new customer: Keith Donovan, DLR06',               '2026-01-15 11:20:40'),
('MBROWN04', 'SDCRT001', 'INS', 'sales_deal',      'DL04000106', NULL,                                'status=WS, vehicle_price=28590.00',                '2026-04-15 16:10:18'),
('MJOHN09',  'SDCRT001', 'INS', 'sales_deal',      'DL09000007', NULL,                                'status=WS, vehicle_price=28590.00',                '2026-04-14 15:45:22'),
('EHART005', 'FACRT001', 'INS', 'finance_app',     'FIN60000906',NULL,                                'status=FN, amount=72433.03',                       '2026-04-14 11:30:15'),
('SLEE0005', 'FACRT001', 'INS', 'finance_app',     'FIN60000905',NULL,                                'status=FN, amount=74433.03',                       '2026-04-01 10:10:20'),
('PCHEN005', 'REGCRT01', 'INS', 'registration',    'REG600000803',NULL,                               'reg_type=LS, status=IS',                           '2026-04-05 09:30:45'),
('WCLARK04', 'RVEH001',  'UPD', 'recall_vehicle',  'RCL2026001/3GNAXKEV0PS100101', 'status=SC',       'status=CM',                                        '2026-03-10 14:25:30'),
('CBENNT09', 'RVEH001',  'UPD', 'recall_vehicle',  'RCL2026002/1GCUYEED5NZ909001', 'status=SC',       'status=CM',                                        '2026-03-30 11:42:15'),
-- Older activity (March 2026)
('JDOE0001', 'SDCRT001', 'INS', 'sales_deal',      'DL01000106', NULL,                                'status=DL, total_gross=3033.00',                   '2026-03-22 11:25:30'),
('APARK002', 'SDCRT001', 'INS', 'sales_deal',      'DL02000102', NULL,                                'status=DL, total_gross=6263.25',                   '2026-03-13 10:47:12'),
('DGOLD07',  'SDCRT001', 'INS', 'sales_deal',      'DL07000004', NULL,                                'status=DL, total_gross=12348.00',                  '2026-03-05 13:22:40'),
('SMART10',  'SDCRT001', 'INS', 'sales_deal',      'DL10000003', NULL,                                'status=DL, total_gross=5043.75',                   '2026-03-30 10:42:18'),
('MRODRI12', 'SDCRT001', 'INS', 'sales_deal',      'DL12000003', NULL,                                'status=DL, total_gross=2842.50',                   '2026-03-10 10:25:50'),
('WCLARK04', 'WCMUPD01', 'UPD', 'warranty_claim',  'CL600007',   'status=NW',                         'status=AP',                                        '2026-03-25 11:10:20'),
('KLEE0003', 'LEADUP01', 'UPD', 'customer_lead',   '8',          'status=NW',                         'status=CT',                                        '2026-03-18 14:20:10'),
('RNGUYEN3', 'STADJ001', 'UPD', 'vehicle',         '19XFC1F38NE503001', 'status=AV',                  'status=HD',                                        '2026-04-10 14:30:08'),
('DFERNA08', 'STADJ001', 'UPD', 'stock_adjustment','459',        NULL,                                'type=AG, note=aged >180 days',                     '2026-04-12 10:15:40'),
('SYSADMIN', 'BATFP001', 'RUN', 'batch_control',   'FPINT',      'last_run=2026-03-31',               'last_run=2026-04-14, records=156',                 '2026-04-14 03:45:00'),
('SYSADMIN', 'BATSTK01', 'RUN', 'batch_control',   'STOCKSUM',   'last_run=2026-04-14',               'last_run=2026-04-15, records=310',                 '2026-04-15 01:30:00'),
-- Even older (Feb/Jan 2026)
('TSMITH01', 'SDCRT001', 'INS', 'sales_deal',      'DL01000107', NULL,                                'status=DL, total_gross=4473.00',                   '2026-02-14 09:32:45'),
('PCHEN005', 'SDCRT001', 'INS', 'sales_deal',      'DL05000103', NULL,                                'status=DL, total_gross=9878.00',                   '2026-01-22 13:47:20'),
('DJONES02', 'SDCRT001', 'INS', 'sales_deal',      'DL02000101', NULL,                                'status=DL, total_gross=5836.10',                   '2025-12-22 14:32:18'),
('JSMITH06', 'SDCRT001', 'INS', 'sales_deal',      'DL06000001', NULL,                                'status=DL, total_gross=2770.00',                   '2026-01-09 11:22:35'),
('BFOSTER9', 'SDCRT001', 'INS', 'sales_deal',      'DL09000002', NULL,                                'status=DL, total_gross=4263.00',                   '2026-01-22 10:32:42'),
('EYOUNG10', 'SDCRT001', 'INS', 'sales_deal',      'DL10000002', NULL,                                'status=DL, total_gross=4743.75',                   '2026-02-20 11:17:15'),
('JWOOD11',  'SDCRT001', 'INS', 'sales_deal',      'DL11000001', NULL,                                'status=DL, total_gross=3648.35',                   '2026-02-22 10:32:18'),
('GLOPE12',  'SDCRT001', 'INS', 'sales_deal',      'DL12000001', NULL,                                'status=DL, total_gross=3105.00',                   '2026-02-02 10:42:10'),
('SYSADMIN', 'USRADM01', 'INS', 'system_user',     'ARUSSO06',   NULL,                                'type=M, dealer=DLR06, active=Y',                   '2026-01-10 09:00:00'),
('SYSADMIN', 'USRADM01', 'INS', 'dealer',          'DLR07',      NULL,                                'name=Charlotte BMW, active=Y',                     '2026-01-10 09:05:15');

-- ── Daily Sales Summary (last 14 days coverage) ─────────────────────
-- ON CONFLICT DO NOTHING guards against V41 pre-existing rows (different
-- dates don't collide, but this is defensive against future overlaps).
INSERT INTO daily_sales_summary (summary_date, dealer_code, model_year, make_code, model_code, units_sold, total_revenue, total_gross, front_gross, back_gross, avg_selling_price, avg_gross_per_unit) VALUES
('2026-04-14', 'DLR05', 2026, 'BMW', 'IX_50E', 1, 88095.00, 15090.00, 7840.00, 7250.00,  88095.00, 15090.00),
('2026-04-13', 'DLR01', 2026, 'FRD', 'EXPLLT', 1, 54955.00,  4677.60, 3177.60, 1500.00,  54955.00,  4677.60),
('2026-04-12', 'DLR02', 2025, 'TYT', 'HGHLXL', 1, 45785.00,  6878.50, 4428.50, 2450.00,  45785.00,  6878.50),
('2026-04-10', 'DLR12', 2025, 'HND', 'PILTEX', 1, 47545.00,  3652.50, 2302.50, 1350.00,  47545.00,  3652.50),
('2026-04-05', 'DLR04', 2025, 'CHV', 'MALIBU', 1, 29785.00,  2279.50, 1429.50,  850.00,  29785.00,  2279.50),
('2026-04-05', 'DLR06', 2026, 'FRD', 'F150XL', 1, 48245.00,  4175.00, 2775.00, 1400.00,  48245.00,  4175.00),
('2026-04-01', 'DLR05', 2026, 'BMW', 'IX_50E', 1, 88095.00, 13332.50, 6532.50, 6800.00,  88095.00, 13332.50),
('2026-03-30', 'DLR01', 2025, 'FRD', 'F150XL', 1, 37895.00,  3033.00, 1958.00, 1075.00,  37895.00,  3033.00),
('2026-03-30', 'DLR06', 2025, 'FRD', 'ESCSEL', 1, 37895.00,  2805.00, 1820.00,  985.00,  37895.00,  2805.00),
('2026-03-30', 'DLR10', 2026, 'TYT', 'CAMRYL', 1, 31395.00,  5043.75, 2268.75, 2775.00,  31395.00,  5043.75),
('2026-03-26', 'DLR09', 2026, 'CHV', 'EQNOLT', 1, 37295.00,  2845.00, 1795.00, 1050.00,  37295.00,  2845.00),
('2026-03-22', 'DLR10', 2025, 'TYT', 'TACSR5', 1, 38585.00,  5857.50, 2607.50, 3250.00,  38585.00,  5857.50),
('2026-03-18', 'DLR01', 2025, 'FRD', 'F150XL', 1, 48245.00,  4237.50, 2812.50, 1425.00,  48245.00,  4237.50),
('2026-03-18', 'DLR05', 2025, 'BMW', 'X5XD40', 1, 68895.00, 10542.50, 5092.50, 5450.00,  68895.00, 10542.50),
('2026-03-16', 'DLR06', 2026, 'FRD', 'F150XL', 1, 48245.00,  3925.00, 2775.00, 1150.00,  48245.00,  3925.00),
('2026-03-12', 'DLR02', 2025, 'TYT', 'HGHLXL', 1, 45785.00,  6263.25, 4163.25, 2100.00,  45785.00,  6263.25)
ON CONFLICT (summary_date, dealer_code, model_year, make_code, model_code) DO NOTHING;

-- ── Monthly Snapshots (12 dealers × March 2026 + 12 × Feb 2026) ─────
-- V41 already has (202602, DLRxx) and (202603, DLRxx) for DLR01-DLR05.
-- ON CONFLICT DO NOTHING preserves V41 data; new DLR06-DLR12 rows insert.
INSERT INTO monthly_snapshot (snapshot_month, dealer_code, total_units_sold, total_revenue, total_gross, total_fi_gross, avg_days_to_sell, inventory_turn, fi_per_deal, csi_score, frozen_flag) VALUES
-- March 2026
('202603', 'DLR01', 4,  188970.00, 15522.60, 5350.00,   45, 1.25, 1337.50, 92.50, 'Y'),
('202603', 'DLR02', 1,  45785.00,  6263.25,  2100.00,   58, 1.10, 2100.00, 89.40, 'Y'),
('202603', 'DLR03', 1,  38950.84,  1470.50,  425.00,   135, 0.55,  425.00, 78.20, 'Y'),
('202603', 'DLR04', 2,  78497.08,  7592.00,  2600.00,   62, 1.05, 1300.00, 85.80, 'Y'),
('202603', 'DLR05', 2, 162908.58, 20232.25,10515.00,    35, 1.45, 5257.50, 94.80, 'Y'),
('202603', 'DLR06', 6,  255700.48, 22420.30, 7600.00,   38, 1.30, 1266.67, 91.20, 'Y'),
('202603', 'DLR07', 2, 148405.67, 20302.00, 9050.00,    42, 1.35, 4525.00, 93.10, 'Y'),
('202603', 'DLR08', 0,  0.00,      0.00,    0.00,      175, 0.35,    0.00, 76.50, 'Y'),
('202603', 'DLR09', 2,  77523.28,  6224.00, 2275.00,    73, 1.00, 1137.50, 84.60, 'Y'),
('202603', 'DLR10', 3, 109202.60, 15984.70, 9150.00,    40, 1.40, 3050.00, 92.80, 'Y'),
('202603', 'DLR11', 2,  89306.97,  7573.00, 2850.00,    55, 1.15, 1425.00, 88.50, 'Y'),
('202603', 'DLR12', 1,  39431.91,  2842.50, 1100.00,    68, 1.05, 1100.00, 87.20, 'Y'),
-- February 2026
('202602', 'DLR01', 2,  88322.92,  8710.50, 2850.00,    48, 1.20, 1425.00, 91.80, 'Y'),
('202602', 'DLR02', 1,  33835.92,  4025.00, 1400.00,    62, 1.05, 1400.00, 88.90, 'Y'),
('202602', 'DLR03', 0,  0.00,      0.00,    0.00,      150, 0.40,    0.00, 77.80, 'Y'),
('202602', 'DLR04', 1,  41202.08,  2845.00, 1050.00,    65, 1.00, 1050.00, 85.20, 'Y'),
('202602', 'DLR05', 1,  51148.58,  7605.00, 4125.00,    38, 1.40, 4125.00, 94.20, 'Y'),
('202602', 'DLR06', 3,  146216.81,12033.15, 3875.00,    40, 1.28, 1291.67, 90.80, 'Y'),
('202602', 'DLR07', 2, 125869.57, 15476.00, 6850.00,    45, 1.32, 3425.00, 92.50, 'Y'),
('202602', 'DLR08', 0,  0.00,      0.00,    0.00,      165, 0.38,    0.00, 76.80, 'Y'),
('202602', 'DLR09', 2,  82220.03,  7642.00, 2650.00,    70, 1.02, 1325.00, 84.90, 'Y'),
('202602', 'DLR10', 3, 117929.45, 16115.70, 8825.00,    42, 1.38, 2941.67, 92.60, 'Y'),
('202602', 'DLR11', 1,  50009.51,  3648.35, 1175.00,    58, 1.12, 1175.00, 88.20, 'Y'),
('202602', 'DLR12', 1,  43616.87,  3105.00, 1175.00,    70, 1.03, 1175.00, 87.50, 'Y')
ON CONFLICT (snapshot_month, dealer_code) DO NOTHING;
