-- V39__seed_deal_details.sql
-- Seed deal_line_item, trade_in, incentive_applied, sales_approval for complete deal detail pages.

-- ── Deal Line Items (pricing breakdown for delivered + financed deals) ──
-- line_type: VP=Vehicle Price, DF=Destination Fee, TX=Tax, TR=Trade Credit, RB=Rebate, AC=Accessory, FE=Doc Fee

-- DL01000001 (DLR01, DL, Ford Escape SEL, sell=36400)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL01000001', 1, 'VP', 'Vehicle — 2025 Ford Escape SEL', 34500.00, 31050.00, 'Y'),
('DL01000001', 2, 'AC', 'All-Weather Floor Mats', 285.00, 95.00, 'Y'),
('DL01000001', 3, 'AC', 'Cargo Organizer', 120.00, 45.00, 'Y'),
('DL01000001', 4, 'DF', 'Destination & Delivery', 1495.00, 1495.00, 'N'),
('DL01000001', 5, 'FE', 'Documentation Fee', 499.00, 0.00, 'N'),
('DL01000001', 6, 'TR', 'Trade-In Allowance', -2500.00, 0.00, 'N'),
('DL01000001', 7, 'TX', 'State & Local Tax (7.15%)', 2501.00, 0.00, 'N');

-- DL01000002 (DLR01, DL, Ford Mustang GT, sell=44090)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL01000002', 1, 'VP', 'Vehicle — 2025 Ford Mustang GT', 42090.00, 37881.00, 'Y'),
('DL01000002', 2, 'AC', 'Ford Performance Stripes', 650.00, 220.00, 'Y'),
('DL01000002', 3, 'DF', 'Destination & Delivery', 1495.00, 1495.00, 'N'),
('DL01000002', 4, 'FE', 'Documentation Fee', 499.00, 0.00, 'N'),
('DL01000002', 5, 'TX', 'State & Local Tax (7.15%)', 3056.00, 0.00, 'N');

-- DL01000003 (DLR01, FI, Ford F-150 XL, sell=44970)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL01000003', 1, 'VP', 'Vehicle — 2025 Ford F-150 XL', 42490.00, 38241.00, 'Y'),
('DL01000003', 2, 'AC', 'Bed Liner Spray-In', 595.00, 180.00, 'Y'),
('DL01000003', 3, 'AC', 'Tonneau Cover', 890.00, 310.00, 'Y'),
('DL01000003', 4, 'DF', 'Destination & Delivery', 1795.00, 1795.00, 'N'),
('DL01000003', 5, 'RB', 'Ford Truck Month Rebate', -1500.00, 0.00, 'N'),
('DL01000003', 6, 'FE', 'Documentation Fee', 499.00, 0.00, 'N'),
('DL01000003', 7, 'TX', 'State & Local Tax (7.15%)', 3141.00, 0.00, 'N');

-- DL02000006 (DLR02, DL, Toyota Camry LE, sell=29495)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL02000006', 1, 'VP', 'Vehicle — 2025 Toyota Camry LE', 28855.00, 26825.00, 'Y'),
('DL02000006', 2, 'DF', 'Destination & Delivery', 1095.00, 1095.00, 'N'),
('DL02000006', 3, 'TR', 'Trade-In Allowance', -3200.00, 0.00, 'N'),
('DL02000006', 4, 'FE', 'Documentation Fee', 399.00, 0.00, 'N'),
('DL02000006', 5, 'TX', 'State & Local Tax (7.0%)', 2346.00, 0.00, 'N');

-- DL02000007 (DLR02, DL, Toyota RAV4 XLE Premium, sell=37535)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL02000007', 1, 'VP', 'Vehicle — 2025 Toyota RAV4 XLE Premium', 35535.00, 32335.00, 'Y'),
('DL02000007', 2, 'AC', 'Roof Rack Cross Bars', 350.00, 120.00, 'Y'),
('DL02000007', 3, 'DF', 'Destination & Delivery', 1335.00, 1335.00, 'N'),
('DL02000007', 4, 'FE', 'Documentation Fee', 399.00, 0.00, 'N'),
('DL02000007', 5, 'TX', 'State & Local Tax (7.0%)', 2516.00, 0.00, 'N');

-- DL02000008 (DLR02, DL, Toyota Tacoma SR5, sell=37250)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL02000008', 1, 'VP', 'Vehicle — 2025 Toyota Tacoma SR5', 35250.00, 31725.00, 'Y'),
('DL02000008', 2, 'AC', 'TRD Off-Road Wheels', 1200.00, 480.00, 'Y'),
('DL02000008', 3, 'DF', 'Destination & Delivery', 1335.00, 1335.00, 'N'),
('DL02000008', 4, 'TR', 'Trade-In Allowance', -4500.00, 0.00, 'N'),
('DL02000008', 5, 'FE', 'Documentation Fee', 399.00, 0.00, 'N'),
('DL02000008', 6, 'TX', 'State & Local Tax (7.0%)', 2566.00, 0.00, 'N');

-- DL03000011 (DLR03, DL, Honda Civic EX, sell=28950)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL03000011', 1, 'VP', 'Vehicle — 2025 Honda Civic EX', 27500.00, 24750.00, 'Y'),
('DL03000011', 2, 'AC', 'Honda Sensing Elite Package', 850.00, 340.00, 'Y'),
('DL03000011', 3, 'DF', 'Destination & Delivery', 1095.00, 1095.00, 'N'),
('DL03000011', 4, 'FE', 'Documentation Fee', 499.00, 0.00, 'N'),
('DL03000011', 5, 'TX', 'State & Local Tax (5.6%)', 1588.00, 0.00, 'N');

-- DL03000013 (DLR03, DL, Honda Pilot Touring, sell=46050)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL03000013', 1, 'VP', 'Vehicle — 2025 Honda Pilot Touring', 43050.00, 38745.00, 'Y'),
('DL03000013', 2, 'AC', 'Running Boards', 495.00, 165.00, 'Y'),
('DL03000013', 3, 'AC', 'Rear Entertainment System', 1100.00, 450.00, 'Y'),
('DL03000013', 4, 'DF', 'Destination & Delivery', 1495.00, 1495.00, 'N'),
('DL03000013', 5, 'TR', 'Trade-In Allowance', -5800.00, 0.00, 'N'),
('DL03000013', 6, 'FE', 'Documentation Fee', 499.00, 0.00, 'N'),
('DL03000013', 7, 'TX', 'State & Local Tax (5.6%)', 2611.00, 0.00, 'N');

-- DL04000016 (DLR04, DL, Chevy Silverado LT, sell=47300)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL04000016', 1, 'VP', 'Vehicle — 2025 Chevrolet Silverado LT', 44300.00, 39870.00, 'Y'),
('DL04000016', 2, 'AC', 'Z71 Off-Road Package', 1500.00, 620.00, 'Y'),
('DL04000016', 3, 'AC', 'Spray-In Bed Liner', 595.00, 180.00, 'Y'),
('DL04000016', 4, 'DF', 'Destination & Delivery', 1895.00, 1895.00, 'N'),
('DL04000016', 5, 'TR', 'Trade-In Allowance', -6200.00, 0.00, 'N'),
('DL04000016', 6, 'FE', 'Documentation Fee', 599.00, 0.00, 'N'),
('DL04000016', 7, 'TX', 'State & Local Tax (7.0%)', 3311.00, 0.00, 'N');

-- DL05000021 (DLR05, DL, BMW 330i xDrive, sell=46400)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL05000021', 1, 'VP', 'Vehicle — 2025 BMW 330i xDrive', 44900.00, 40410.00, 'Y'),
('DL05000021', 2, 'AC', 'M Sport Package', 900.00, 360.00, 'Y'),
('DL05000021', 3, 'DF', 'Destination & Delivery', 995.00, 995.00, 'N'),
('DL05000021', 4, 'FE', 'Documentation Fee', 699.00, 0.00, 'N'),
('DL05000021', 5, 'TX', 'State & Local Tax (6.35%)', 2906.00, 0.00, 'N');

-- DL05000022 (DLR05, DL, BMW X5 xDrive40i, sell=67900)
INSERT INTO deal_line_item (deal_number, line_seq, line_type, description, amount, cost, taxable_flag) VALUES
('DL05000022', 1, 'VP', 'Vehicle — 2025 BMW X5 xDrive40i', 65200.00, 58680.00, 'Y'),
('DL05000022', 2, 'AC', 'Premium Package', 1450.00, 580.00, 'Y'),
('DL05000022', 3, 'AC', 'Tow Hitch', 650.00, 260.00, 'Y'),
('DL05000022', 4, 'DF', 'Destination & Delivery', 995.00, 995.00, 'N'),
('DL05000022', 5, 'TR', 'Trade-In Allowance', -8500.00, 0.00, 'N'),
('DL05000022', 6, 'FE', 'Documentation Fee', 699.00, 0.00, 'N'),
('DL05000022', 7, 'TX', 'State & Local Tax (6.35%)', 4106.00, 0.00, 'N');

-- ── Trade-Ins (for deals that had trade credits) ────────────────────
INSERT INTO trade_in (deal_number, vin, trade_year, trade_make, trade_model, trade_color, odometer, condition_code, acv_amount, allowance_amt, over_allow, payoff_amt, payoff_bank, payoff_acct, appraised_by, appraised_ts) VALUES
('DL01000001', '2FMDK3GC8FBA12345', 2015, 'Ford',      'Edge SEL',         'Silver',  87500, 'G', 2200.00, 2500.00, 300.00, 0.00, NULL, NULL, 'TSMITH01', '2025-07-15 10:30:00'),
('DL02000006', '4T1BF1FK2EU123456', 2014, 'Toyota',     'Camry SE',         'Blue',    95200, 'F', 2800.00, 3200.00, 400.00, 1200.00, 'Wells Fargo', 'WF-98765', 'DJONES02', '2025-08-10 14:15:00'),
('DL02000008', '3TMCZ5AN7LM234567', 2020, 'Toyota',     'Tacoma TRD Sport', 'White',   42300, 'G', 4200.00, 4500.00, 300.00, 8500.00, 'Chase Auto', 'CH-44321', 'DJONES02', '2025-09-05 09:45:00'),
('DL03000013', '5FNYF6H53KB345678', 2019, 'Honda',      'Pilot EX-L',       'Black',   58700, 'G', 5500.00, 5800.00, 300.00, 3200.00, 'Capital One', 'CO-77123', 'KLEE0003', '2025-08-20 11:00:00'),
('DL04000016', '1GCUYEED1MZ456789', 2021, 'Chevrolet',  'Silverado Custom', 'Red',     38200, 'E', 6000.00, 6200.00, 200.00, 12500.00, 'Ally Financial', 'AL-55678', 'MBROWN04', '2025-09-15 13:30:00'),
('DL05000022', 'WBAPH5G56BNM67890', 2011, 'BMW',        'X3 xDrive28i',     'Gray',    72400, 'F', 7800.00, 8500.00, 700.00, 0.00, NULL, NULL, 'PCHEN005', '2025-10-01 15:45:00');

-- ── Incentives Applied ──────────────────────────────────────────────
INSERT INTO incentive_applied (deal_number, incentive_id, amount_applied, applied_ts) VALUES
('DL01000003', 'INC2025001', 1500.00, '2025-08-15 10:00:00'),
('DL01000001', 'INC2025001', 750.00,  '2025-07-20 14:00:00'),
('DL02000006', 'INC2025002', 500.00,  '2025-08-12 11:30:00'),
('DL02000007', 'INC2025002', 500.00,  '2025-09-02 16:00:00'),
('DL02000008', 'INC2025002', 500.00,  '2025-09-08 09:15:00'),
('DL03000011', 'INC2025002', 500.00,  '2025-08-25 10:45:00');

-- ── Sales Approvals (manager + finance approvals) ───────────────────
-- approval_type: MG=Manager, FI=Finance, GM=General Manager
-- approval_status: A=Approved, R=Rejected, P=Pending
INSERT INTO sales_approval (deal_number, approval_type, approver_id, approval_status, comments, approval_ts) VALUES
('DL01000001', 'MG', 'JPATTER1', 'A', 'Good gross, approved',                          '2025-07-18 09:00:00'),
('DL01000001', 'FI', 'JPATTER1', 'A', 'Finance docs complete',                         '2025-07-19 14:30:00'),
('DL01000002', 'MG', 'JPATTER1', 'A', 'Approved — strong back-end',                    '2025-09-10 10:15:00'),
('DL01000003', 'MG', 'JPATTER1', 'A', 'Rebate applied, gross acceptable',              '2025-08-16 11:00:00'),
('DL02000006', 'MG', 'MSANTOS1', 'A', 'Trade value fair, deal approved',               '2025-08-11 15:00:00'),
('DL02000007', 'MG', 'MSANTOS1', 'A', 'Approved',                                      '2025-09-03 09:30:00'),
('DL02000008', 'MG', 'MSANTOS1', 'A', 'Trade payoff verified with Chase',              '2025-09-06 14:00:00'),
('DL02000008', 'FI', 'MSANTOS1', 'A', 'Lender approved, docs signed',                  '2025-09-07 10:00:00'),
('DL03000011', 'MG', 'RNGUYEN3', 'A', 'Approved — loyalty customer',                   '2025-08-22 09:45:00'),
('DL03000013', 'MG', 'RNGUYEN3', 'A', 'Excellent gross, approved',                     '2025-08-21 16:00:00'),
('DL03000013', 'GM', 'RNGUYEN3', 'A', 'GM override — over-allowance on trade approved','2025-08-21 16:30:00'),
('DL03000014', 'MG', 'RNGUYEN3', 'P', 'Pending review — need updated credit report',   '2025-09-20 11:00:00'),
('DL04000016', 'MG', 'WCLARK04', 'A', 'Approved — truck month push',                   '2025-09-16 10:00:00'),
('DL04000016', 'FI', 'WCLARK04', 'A', 'Ally approved at 5.9%',                         '2025-09-17 14:00:00'),
('DL05000021', 'MG', 'EHART005', 'A', 'Approved',                                      '2025-10-02 09:00:00'),
('DL05000022', 'MG', 'EHART005', 'A', 'Trade value approved per KBB',                  '2025-10-05 11:00:00'),
('DL05000022', 'FI', 'EHART005', 'A', 'BMW FS approved at 4.9%',                       '2025-10-06 10:00:00'),
('DL05000025', 'MG', 'EHART005', 'P', 'Awaiting credit decision',                      '2026-03-15 14:00:00'),
('DL01000005', 'MG', 'JPATTER1', 'R', 'Deal cancelled by customer — cold feet',        '2025-10-20 16:00:00');
