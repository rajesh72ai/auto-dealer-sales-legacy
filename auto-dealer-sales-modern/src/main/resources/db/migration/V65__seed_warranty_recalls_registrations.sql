-- ==========================================================================
-- V65: Warranty contracts + warranty claims + recall campaigns + registrations
-- Persona signals:
--   DLR04/09 (Warranty hotspot): heavy claim volume, open recall campaigns
--   DLR05/10 (F&I powerhouse):   extended warranty attach from V64 products
--   DLR03/08 (Struggling):       few claims (low volume base)
-- Pure INSERT only.
-- ==========================================================================

-- ── Warranty Contracts (30 contracts tied to delivered deals) ───────
-- warranty_id is IDENTITY — auto-assigned
INSERT INTO warranty (vin, deal_number, warranty_type, start_date, expiry_date, mileage_limit, deductible, active_flag) VALUES
-- Base manufacturer warranties (BA) from DL deals
('1FTFW1E53NFA01501', 'DL01000101', 'BA', '2025-11-18', '2028-11-18', 36000,   0.00, 'Y'),
('1FTFW1E53NFA01502', 'DL01000102', 'BA', '2025-12-27', '2028-12-27', 36000,   0.00, 'Y'),
('1FTFW1E53PFA01503', 'DL01000103', 'BA', '2026-02-14', '2029-02-14', 36000,   0.00, 'Y'),
('1FMCU9J93NUA01501', 'DL01000105', 'BA', '2026-01-08', '2029-01-08', 36000,   0.00, 'Y'),
('1FA6P8CF7N5A01501', 'DL01000107', 'BA', '2026-02-18', '2029-02-18', 36000,   0.00, 'Y'),
('1FM5K8GC7PGA01501', 'DL01000108', 'BA', '2026-04-03', '2029-04-03', 36000,   0.00, 'Y'),
-- DLR06 (Ford base + some extended)
('1FMCU9J93NUA06101', 'DL06000001', 'BA', '2026-01-13', '2029-01-13', 36000,   0.00, 'Y'),
('1FA6P8CF7N5A06202', 'DL06000002', 'BA', '2026-03-20', '2029-03-20', 36000,   0.00, 'Y'),
('1FTFW1E53PFA06003', 'DL06000005', 'EX', '2026-03-16', '2032-03-16', 100000,  100.00, 'Y'),
('1FM5K8GC7PGA06301', 'DL06000008', 'EX', '2026-03-12', '2033-03-12', 100000,  100.00, 'Y'),
-- DLR02 (Toyota)
('5TDBKRFH5NS401501', 'DL02000101', 'BA', '2025-12-27', '2028-12-27', 36000,   0.00, 'Y'),
('5TDBKRFH5NS401502', 'DL02000102', 'EX', '2026-03-17', '2033-03-17', 100000,  100.00, 'Y'),
('5TDBKRFH5NS401503', 'DL02000103', 'BA', '2026-04-14', '2029-04-14', 36000,   0.00, 'Y'),
-- DLR07 BMW (heavy extended)
('WBA5R1C50NFJ07001', 'DL07000001', 'EX', '2025-12-23', '2032-12-23', 100000,  100.00, 'Y'),
('WBA5R1C50NFJ07002', 'DL07000002', 'BA', '2026-02-26', '2030-02-26', 50000,   0.00, 'Y'),
('5UXCR6C05NLL07001', 'DL07000003', 'EX', '2026-01-17', '2034-01-17', 120000,  150.00, 'Y'),
('5UXCR6C05NLL07002', 'DL07000004', 'EX', '2026-03-09', '2034-03-09', 120000,  150.00, 'Y'),
('WBY73AW05PFM07001', 'DL07000005', 'EX', '2026-03-04', '2036-03-04', 150000,  150.00, 'Y'),
-- DLR03 Honda (struggling — only base)
('19XFC1F38NE501501', 'DL03000101', 'BA', '2025-08-14', '2028-08-14', 36000,   0.00, 'Y'),
('7FARW2H93NE601501', 'DL03000102', 'BA', '2025-10-30', '2028-10-30', 36000,   0.00, 'Y'),
-- DLR04 Chevy (warranty hotspot — heavy extended due to concerns)
('1GCUYEED5NZ901501', 'DL04000101', 'EX', '2025-11-25', '2032-11-25', 100000,  100.00, 'Y'),
('1GCUYEED5NZ901502', 'DL04000102', 'EX', '2026-01-14', '2032-01-14', 100000,  100.00, 'Y'),
('3GNAXKEV0PS101501', 'DL04000103', 'BA', '2026-02-22', '2029-02-22', 36000,   0.00, 'Y'),
('3GNAXKEV0PS101502', 'DL04000104', 'EX', '2026-03-30', '2033-03-30', 100000,  100.00, 'Y'),
-- DLR09 Chevy (warranty hotspot #2)
('1GCUYEED5NZ909001', 'DL09000001', 'EX', '2025-12-20', '2032-12-20', 100000,  100.00, 'Y'),
('1GCUYEED5NZ909002', 'DL09000002', 'EX', '2026-01-26', '2033-01-26', 100000,  100.00, 'Y'),
('3GNAXKEV0PS109001', 'DL09000004', 'EX', '2026-01-16', '2034-01-16', 100000,  100.00, 'Y'),
-- DLR05 BMW (F&I powerhouse — all extended via F&I attach)
('WBA5R1C50NFJ01501', 'DL05000101', 'EX', '2025-12-22', '2032-12-22', 100000,  100.00, 'Y'),
('5UXCR6C05NLL01501', 'DL05000103', 'EX', '2026-01-26', '2034-01-26', 120000,  150.00, 'Y'),
('WBY73AW05PFM01501', 'DL05000105', 'EX', '2026-04-05', '2036-04-05', 150000,  150.00, 'Y'),
-- DLR10 Toyota (F&I powerhouse #2)
('4T1BF1FK5NU101001', 'DL10000001', 'EX', '2026-01-12', '2032-01-12', 75000,   100.00, 'Y'),
('2T3WFREV5NW201001', 'DL10000004', 'EX', '2026-01-22', '2033-01-22', 100000,  100.00, 'Y'),
('5TDBKRFH5NS401001', 'DL10000008', 'EX', '2026-01-27', '2033-01-27', 100000,  100.00, 'Y'),
-- DLR11/12 baseline
('1FTFW1E53NFA11002', 'DL11000001', 'BA', '2026-02-26', '2029-02-26', 36000,   0.00, 'Y'),
('1FM5K8GC7PGA11301', 'DL11000005', 'EX', '2026-03-04', '2033-03-04', 100000,  100.00, 'Y'),
('7FARW2H93NE612001', 'DL12000001', 'BA', '2026-02-06', '2029-02-06', 36000,   0.00, 'Y'),
('5FNYF6H95NB812001', 'DL12000004', 'EX', '2026-04-10', '2033-04-10', 100000,  100.00, 'Y');

-- ── Warranty Claims ──────────────────────────────────────────────────
-- DLR04/09 heavy (hotspot persona), others light. 28 total claims.
INSERT INTO warranty_claim (claim_number, vin, dealer_code, claim_type, claim_date, repair_date, labor_amt, parts_amt, total_claim, claim_status, technician_id, repair_order_num, notes) VALUES
-- DLR04 WARRANTY HOTSPOT — 9 claims across varied vehicles
('CL600001', '1GCUYEED5NZ900101', 'DLR04', 'PT', '2025-12-10', '2025-12-14',  850.00, 1250.00, 2100.00, 'AP', 'WCLARK04', 'RO04000201', 'Transmission shift shock fixed; TSB update'),
('CL600002', '1GCUYEED5NZ900102', 'DLR04', 'BA', '2026-01-15', '2026-01-18',  420.00,  680.00, 1100.00, 'CL', 'WCLARK04', 'RO04000202', 'Infotainment screen replaced under base warranty'),
('CL600003', '3GNAXKEV0PS100101', 'DLR04', 'EX', '2026-02-05', '2026-02-08',  650.00,  950.00, 1600.00, 'AP', 'WCLARK04', 'RO04000203', 'EV coolant leak — pump replaced'),
('CL600004', '1GCUYEED5NZ901501', 'DLR04', 'PT', '2026-02-18', '2026-02-22', 1100.00, 1850.00, 2950.00, 'CL', 'WCLARK04', 'RO04000204', 'Fuel pump failure at 3K miles — rare'),
('CL600005', '3GNAXKEV0PS101501', 'DLR04', 'EX', '2026-03-01', '2026-03-05',  780.00, 1200.00, 1980.00, 'AP', 'WCLARK04', 'RO04000205', 'Battery module diagnostic fault'),
('CL600006', '1G1ZD5STXNF200101', 'DLR04', 'BA', '2026-03-08', NULL,          350.00,  420.00,  770.00, 'IP', 'WCLARK04', 'RO04000206', 'A/C blowing warm — compressor on order'),
('CL600007', '3GNAXKEV0PS101502', 'DLR04', 'EX', '2026-03-25', '2026-03-28',  920.00, 1450.00, 2370.00, 'AP', 'WCLARK04', 'RO04000207', 'Inverter warning light repeat'),
('CL600008', '1G1ZD5STXNF201501', 'DLR04', 'BA', '2026-04-08', NULL,          280.00,  350.00,  630.00, 'NW', NULL,       NULL,         'Reported rattling from dashboard; appt scheduled'),
('CL600009', '1GCUYEED5NZ901502', 'DLR04', 'PT', '2026-04-12', NULL,          500.00,  800.00, 1300.00, 'PA', 'WCLARK04', 'RO04000209', 'Transfer case noise; parts approved'),
-- DLR09 WARRANTY HOTSPOT #2 — 8 claims
('CL600010', '1GCUYEED5NZ909001', 'DLR09', 'EX', '2026-02-05', '2026-02-10', 1250.00, 1850.00, 3100.00, 'CL', 'CBENNT09', 'RO09000301', 'Transmission solenoid recall repair'),
('CL600011', '1GCUYEED5NZ909002', 'DLR09', 'PT', '2026-02-20', '2026-02-24',  980.00, 1450.00, 2430.00, 'AP', 'CBENNT09', 'RO09000302', 'Engine stall at idle; ECM reflash'),
('CL600012', '3GNAXKEV0PS109001', 'DLR09', 'EX', '2026-03-01', '2026-03-04',  820.00, 1200.00, 2020.00, 'CL', 'CBENNT09', 'RO09000303', 'EV battery thermal warning fixed'),
('CL600013', '3GNAXKEV0PS109002', 'DLR09', 'EX', '2026-03-15', NULL,         1050.00, 1650.00, 2700.00, 'IP', 'CBENNT09', 'RO09000304', 'Drive unit replacement in progress'),
('CL600014', '1G1ZD5STXNF209001', 'DLR09', 'BA', '2026-03-22', '2026-03-26',  350.00,  520.00,  870.00, 'CL', 'CBENNT09', 'RO09000305', 'Windshield wiper motor replaced'),
('CL600015', '3GNAXKEV0PS109003', 'DLR09', 'EX', '2026-04-01', NULL,          890.00, 1350.00, 2240.00, 'PA', 'CBENNT09', 'RO09000306', 'High-voltage battery imbalance; parts ordered'),
('CL600016', '1GCUYEED5NZ909003', 'DLR09', 'PT', '2026-04-10', NULL,          420.00,  680.00, 1100.00, 'NW', NULL,       NULL,         'Customer reports clunk in 4WD; diagnosing'),
('CL600017', '1GCUYEED5NZ909004', 'DLR09', 'BA', '2026-04-14', NULL,          250.00,  380.00,  630.00, 'NW', NULL,       NULL,         'Intermittent infotainment reboot'),
-- Other dealers (minor claim counts)
('CL600018', '1FTFW1E53NFA00101', 'DLR01', 'BA', '2026-03-10', '2026-03-12',  320.00,  480.00,  800.00, 'CL', 'JPATTER1', 'RO01000101', 'Backup camera fuzzy; module replaced'),
('CL600019', '1FA6P8CF7N5A00401', 'DLR01', 'PT', '2026-04-02', '2026-04-04',  650.00,  920.00, 1570.00, 'AP', 'JPATTER1', 'RO01000102', 'Clutch adjustment under powertrain warranty'),
('CL600020', '4T1BF1FK5NU100101', 'DLR02', 'BA', '2026-02-15', '2026-02-18',  280.00,  350.00,  630.00, 'CL', 'MSANTOS1', 'RO02000101', 'Hybrid battery cell balancing'),
('CL600021', '19XFC1F38NE500101', 'DLR03', 'BA', '2026-01-20', '2026-01-22',  220.00,  180.00,  400.00, 'CL', 'RNGUYEN3', 'RO03000101', 'Minor door lock actuator issue'),
('CL600022', 'WBA5R1C50NFJ00101', 'DLR05', 'EX', '2026-03-18', '2026-03-22',  650.00,  950.00, 1600.00, 'CL', 'EHART005', 'RO05000101', 'iDrive software update, covered under extended'),
('CL600023', '5UXCR6C05NLL00201', 'DLR05', 'EX', '2026-04-05', NULL,          520.00,  750.00, 1270.00, 'IP', 'EHART005', 'RO05000102', 'Adaptive suspension calibration'),
-- DLR06 (volume leader) — normal claim rate
('CL600024', '1FMCU9J93NUA06101', 'DLR06', 'BA', '2026-03-15', '2026-03-18',  280.00,  380.00,  660.00, 'CL', 'ARUSSO06', 'RO06000101', 'Door weather seal replacement'),
('CL600025', '1FA6P8CF7N5A06202', 'DLR06', 'PT', '2026-04-10', NULL,          420.00,  620.00, 1040.00, 'IP', 'ARUSSO06', 'RO06000102', 'Transmission fluid leak diagnostic'),
-- DLR08 (struggling) — few claims
('CL600026', '19XFC1F38NE508001', 'DLR08', 'BA', '2026-01-10', '2026-01-15',  180.00,  220.00,  400.00, 'CL', 'DFERNA08', 'RO08000101', 'Horn not working; diagnosed to steering column switch'),
-- DLR10 (F&I powerhouse) — some extended claims since attach is high
('CL600027', '4T1BF1FK5NU101001', 'DLR10', 'EX', '2026-02-20', '2026-02-23',  450.00,  680.00, 1130.00, 'CL', 'RLARSE10', 'RO10000101', 'Infotainment screen flicker — covered by platinum VSC'),
('CL600028', '2T3WFREV5NW201001', 'DLR10', 'EX', '2026-03-25', '2026-03-28',  520.00,  780.00, 1300.00, 'CL', 'RLARSE10', 'RO10000102', 'Hybrid cooling pump replacement under extended');

-- ── Recall Campaigns (2 new campaigns — hotspot for DLR04/09) ───────
INSERT INTO recall_campaign (recall_id, nhtsa_num, recall_desc, severity, affected_years, affected_models, remedy_desc, remedy_avail_dt, announced_date, total_affected, total_completed, campaign_status) VALUES
('RCL2026001', '26V0142', 'Chevrolet Equinox EV: Potential battery thermal runaway due to cell imbalance. Risk of fire under extreme conditions.', 'H', '2025-2026', 'EQNOLT', 'Dealer will reflash BMS software and inspect battery module for signs of degradation. If detected, module replacement is covered.', '2026-03-15', '2026-02-28', 420, 87, 'A'),
('RCL2026002', '26V0218', 'Chevrolet Silverado 1500: Electronic power steering assist may intermittently fail at low speeds, increasing risk of crash.', 'H', '2025', 'SILVLT', 'Dealer will update EPS control module software. If vehicle has already exhibited symptoms, steering column assembly will be replaced.', '2026-04-01', '2026-03-20', 312, 41, 'A');

-- ── Recall Vehicles (18 VINs — concentrated on DLR04/09) ────────────
INSERT INTO recall_vehicle (recall_id, vin, dealer_code, recall_status, notified_date, scheduled_date, completed_date, technician_id, parts_ordered, parts_avail) VALUES
-- RCL2026001 Equinox EV battery (DLR04/09 heavy)
('RCL2026001', '3GNAXKEV0PS100101', 'DLR04', 'CM', '2026-03-01', '2026-03-10', '2026-03-10', 'WCLARK04', 'N', 'Y'),
('RCL2026001', '3GNAXKEV0PS100102', 'DLR04', 'CM', '2026-03-05', '2026-03-12', '2026-03-12', 'WCLARK04', 'N', 'Y'),
('RCL2026001', '3GNAXKEV0PS100103', 'DLR04', 'SC', '2026-03-20', '2026-04-25', NULL,         NULL,       'Y', 'N'),
('RCL2026001', '3GNAXKEV0PS101501', 'DLR04', 'CM', '2026-03-02', '2026-03-08', '2026-03-08', 'WCLARK04', 'N', 'Y'),
('RCL2026001', '3GNAXKEV0PS101502', 'DLR04', 'CM', '2026-04-01', '2026-04-06', '2026-04-06', 'WCLARK04', 'N', 'Y'),
('RCL2026001', '3GNAXKEV0PS109001', 'DLR09', 'CM', '2026-03-05', '2026-03-15', '2026-03-15', 'CBENNT09', 'N', 'Y'),
('RCL2026001', '3GNAXKEV0PS109002', 'DLR09', 'SC', '2026-03-18', '2026-04-22', NULL,         NULL,       'Y', 'Y'),
('RCL2026001', '3GNAXKEV0PS109003', 'DLR09', 'OP', '2026-04-01', NULL,         NULL,         NULL,       'N', 'N'),
-- RCL2026002 Silverado EPS (DLR04/09)
('RCL2026002', '1GCUYEED5NZ900101', 'DLR04', 'CM', '2026-03-25', '2026-04-02', '2026-04-02', 'WCLARK04', 'N', 'Y'),
('RCL2026002', '1GCUYEED5NZ900102', 'DLR04', 'SC', '2026-03-26', '2026-04-20', NULL,         NULL,       'Y', 'Y'),
('RCL2026002', '1GCUYEED5NZ900103', 'DLR04', 'OP', '2026-03-28', NULL,         NULL,         NULL,       'N', 'N'),
('RCL2026002', '1GCUYEED5NZ901501', 'DLR04', 'SC', '2026-04-05', '2026-04-28', NULL,         NULL,       'Y', 'Y'),
('RCL2026002', '1GCUYEED5NZ901502', 'DLR04', 'OP', '2026-04-08', NULL,         NULL,         NULL,       'N', 'N'),
('RCL2026002', '1GCUYEED5NZ909001', 'DLR09', 'CM', '2026-03-22', '2026-03-30', '2026-03-30', 'CBENNT09', 'N', 'Y'),
('RCL2026002', '1GCUYEED5NZ909002', 'DLR09', 'CM', '2026-03-25', '2026-04-05', '2026-04-05', 'CBENNT09', 'N', 'Y'),
('RCL2026002', '1GCUYEED5NZ909003', 'DLR09', 'SC', '2026-04-01', '2026-04-25', NULL,         NULL,       'Y', 'Y'),
('RCL2026002', '1GCUYEED5NZ909004', 'DLR09', 'OP', '2026-04-10', NULL,         NULL,         NULL,       'N', 'N'),
-- Also affects DLR01 vehicles (1 Silverado edge case cross-dealer)
('RCL2026002', '1FTFW1E53NFA01501', 'DLR01', 'NA', NULL,         NULL,         NULL,         NULL,       'N', 'N');

-- ── Recall Notifications ─────────────────────────────────────────────
INSERT INTO recall_notification (recall_id, vin, customer_id, notif_type, notif_date, response_flag) VALUES
('RCL2026001', '3GNAXKEV0PS100101', 19, 'M', '2026-03-01', 'Y'),
('RCL2026001', '3GNAXKEV0PS100102', 20, 'M', '2026-03-05', 'Y'),
('RCL2026001', '3GNAXKEV0PS100103', 21, 'M', '2026-03-20', 'N'),
('RCL2026001', '3GNAXKEV0PS101501', 21, 'E', '2026-03-02', 'Y'),
('RCL2026001', '3GNAXKEV0PS101502', 22, 'E', '2026-04-01', 'Y'),
('RCL2026001', '3GNAXKEV0PS109001', 18, 'M', '2026-03-05', 'Y'),
('RCL2026001', '3GNAXKEV0PS109002', 19, 'M', '2026-03-18', 'Y'),
('RCL2026001', '3GNAXKEV0PS109003', 20, 'E', '2026-04-01', 'N'),
('RCL2026002', '1GCUYEED5NZ900101', 19, 'M', '2026-03-25', 'Y'),
('RCL2026002', '1GCUYEED5NZ900102', 20, 'M', '2026-03-26', 'Y'),
('RCL2026002', '1GCUYEED5NZ901501', 19, 'E', '2026-04-05', 'Y'),
('RCL2026002', '1GCUYEED5NZ901502', 20, 'E', '2026-04-08', 'N'),
('RCL2026002', '1GCUYEED5NZ909001', 15, 'M', '2026-03-22', 'Y'),
('RCL2026002', '1GCUYEED5NZ909002', 16, 'M', '2026-03-25', 'Y'),
('RCL2026002', '1GCUYEED5NZ909003', 17, 'E', '2026-04-01', 'Y'),
('RCL2026002', '1GCUYEED5NZ909004', 18, 'E', '2026-04-10', 'N');

-- ── Registrations (35 for delivered deals) ──────────────────────────
-- reg_id pattern: REG6xxxxxxxxx (12 chars)
INSERT INTO registration (reg_id, deal_number, vin, customer_id, reg_state, reg_type, plate_number, title_number, lien_holder, reg_status, submission_date, issued_date, reg_fee_paid, title_fee_paid) VALUES
('REG600000101', 'DL01000101', '1FTFW1E53NFA01501', 1,  'CO', 'NV', 'CO-AUT101', 'CO-T2025-11-001', 'Ally Financial',            'CM', '2025-11-18', '2025-11-28', 50.00, 7.20),
('REG600000102', 'DL01000102', '1FTFW1E53NFA01502', 2,  'CO', 'NV', 'CO-AUT102', 'CO-T2025-12-001', 'Chase Auto Finance',        'CM', '2025-12-27', '2026-01-08', 50.00, 7.20),
('REG600000103', 'DL01000103', '1FTFW1E53PFA01503', 3,  'CO', 'NV', 'CO-AUT103', 'CO-T2026-02-001', 'Ally Financial',            'CM', '2026-02-14', '2026-02-24', 50.00, 7.20),
('REG600000104', 'DL01000104', '1FTFW1E53PFA01504', 4,  'CO', 'NV', 'CO-AUT104', 'CO-T2026-03-001', 'Capital One Auto',          'IS', '2026-03-22', '2026-04-02', 50.00, 7.20),
('REG600000105', 'DL01000105', '1FMCU9J93NUA01501', 5,  'CO', 'NV', 'CO-AUT105', 'CO-T2026-01-001', 'Ally Financial',            'CM', '2026-01-08', '2026-01-18', 50.00, 7.20),
('REG600000107', 'DL01000107', '1FA6P8CF7N5A01501', 6,  'CO', 'NV', 'CO-AUT107', 'CO-T2026-02-002', 'Ally Financial',            'CM', '2026-02-18', '2026-02-28', 50.00, 7.20),
('REG600000108', 'DL01000108', '1FM5K8GC7PGA01501', 2,  'CO', 'NV', 'CO-AUT108', 'CO-T2026-04-001', 'Wells Fargo Dealer Svcs',   'SB', '2026-04-03', NULL,         50.00, 7.20),
('REG600000201', 'DL06000001', '1FMCU9J93NUA06101', 7,  'NJ', 'NV', 'NJ-AUT601', 'NJ-T2026-01-001', 'Chase Auto Finance',        'CM', '2026-01-13', '2026-01-23', 46.00, 60.00),
('REG600000202', 'DL06000002', '1FA6P8CF7N5A06202', 8,  'NJ', 'NV', 'NJ-AUT602', 'NJ-T2026-03-001', 'Ally Financial',            'CM', '2026-03-20', '2026-03-30', 46.00, 60.00),
('REG600000203', 'DL06000003', '1FTFW1E53NFA06001', 9,  'NJ', 'NV', 'NJ-AUT603', 'NJ-T2026-02-001', 'Capital One Auto',          'CM', '2026-02-02', '2026-02-12', 46.00, 60.00),
('REG600000204', 'DL06000004', '1FTFW1E53NFA06002', 10, 'NJ', 'NV', 'NJ-AUT604', 'NJ-T2026-02-002', 'Ally Financial',            'CM', '2026-02-24', '2026-03-06', 46.00, 60.00),
('REG600000205', 'DL06000005', '1FTFW1E53PFA06003', 11, 'NJ', 'NV', 'NJ-AUT605', 'NJ-T2026-03-002', 'Chase Auto Finance',        'IS', '2026-03-16', '2026-03-26', 46.00, 60.00),
('REG600000301', 'DL02000101', '5TDBKRFH5NS401501', 8,  'IN', 'NV', 'IN-AUT021', 'IN-T2025-12-001', 'Ally Financial',            'CM', '2025-12-27', '2026-01-06', 21.35, 15.00),
('REG600000302', 'DL02000102', '5TDBKRFH5NS401502', 9,  'IN', 'NV', 'IN-AUT022', 'IN-T2026-03-001', 'Chase Auto Finance',        'CM', '2026-03-17', '2026-03-27', 21.35, 15.00),
('REG600000303', 'DL02000103', '5TDBKRFH5NS401503', 10, 'IN', 'LS', 'IN-AUT023', 'IN-T2026-04-001', 'Ally Financial',            'IS', '2026-04-14', '2026-04-24', 21.35, 15.00),
('REG600000401', 'DL07000001', 'WBA5R1C50NFJ07001', 25, 'NC', 'LS', 'NC-AUT071', 'NC-T2025-12-001', 'BMW Financial Services',    'CM', '2025-12-23', '2026-01-02', 52.00, 14.00),
('REG600000402', 'DL07000002', 'WBA5R1C50NFJ07002', 26, 'NC', 'NV', 'NC-AUT072', 'NC-T2026-02-001', 'BMW Financial Services',    'CM', '2026-02-26', '2026-03-08', 52.00, 14.00),
('REG600000403', 'DL07000003', '5UXCR6C05NLL07001', 27, 'NC', 'NV', 'NC-AUT073', 'NC-T2026-01-001', 'BMW Financial Services',    'CM', '2026-01-17', '2026-01-27', 52.00, 14.00),
('REG600000404', 'DL07000004', '5UXCR6C05NLL07002', 28, 'NC', 'LS', 'NC-AUT074', 'NC-T2026-03-001', 'BMW Financial Services',    'CM', '2026-03-09', '2026-03-19', 52.00, 14.00),
('REG600000405', 'DL07000005', 'WBY73AW05PFM07001', 29, 'NC', 'LS', 'NC-AUT075', 'NC-T2026-03-002', 'BMW Financial Services',    'IS', '2026-03-04', '2026-03-14', 52.00, 14.00),
('REG600000501', 'DL03000101', '19XFC1F38NE501501', 13, 'AZ', 'NV', 'AZ-AUT031', 'AZ-T2025-08-001', 'Capital One Auto',          'CM', '2025-08-14', '2025-08-24', 32.00, 4.00),
('REG600000502', 'DL03000102', '7FARW2H93NE601501', 14, 'AZ', 'NV', 'AZ-AUT032', 'AZ-T2025-10-001', 'Wells Fargo Dealer Svcs',   'CM', '2025-10-30', '2025-11-09', 32.00, 4.00),
('REG600000503', 'DL03000103', '1HGCV3F16PA701501', 15, 'AZ', 'NV', 'AZ-AUT033', 'AZ-T2026-03-001', 'Capital One Auto',          'IS', '2026-03-22', '2026-04-01', 32.00, 4.00),
('REG600000601', 'DL04000101', '1GCUYEED5NZ901501', 19, 'GA', 'NV', 'GA-AUT041', 'GA-T2025-11-001', 'Chase Auto Finance',        'CM', '2025-11-25', '2025-12-05', 20.00, 18.00),
('REG600000602', 'DL04000102', '1GCUYEED5NZ901502', 20, 'GA', 'NV', 'GA-AUT042', 'GA-T2026-01-001', 'Ally Financial',            'CM', '2026-01-14', '2026-01-24', 20.00, 18.00),
('REG600000603', 'DL04000103', '3GNAXKEV0PS101501', 21, 'GA', 'NV', 'GA-AUT043', 'GA-T2026-02-001', 'Chase Auto Finance',        'CM', '2026-02-22', '2026-03-04', 20.00, 18.00),
('REG600000701', 'DL09000001', '1GCUYEED5NZ909001', 15, 'TX', 'NV', 'TX-AUT091', 'TX-T2025-12-001', 'Chase Auto Finance',        'CM', '2025-12-20', '2025-12-30', 51.75, 28.00),
('REG600000702', 'DL09000002', '1GCUYEED5NZ909002', 16, 'TX', 'NV', 'TX-AUT092', 'TX-T2026-01-001', 'Ally Financial',            'CM', '2026-01-26', '2026-02-05', 51.75, 28.00),
('REG600000703', 'DL09000003', '1GCUYEED5NZ909003', 17, 'TX', 'NV', 'TX-AUT093', 'TX-T2026-03-001', 'Capital One Auto',          'IS', '2026-03-02', '2026-03-12', 51.75, 28.00),
('REG600000801', 'DL05000101', 'WBA5R1C50NFJ01501', 25, 'CT', 'LS', 'CT-AUT051', 'CT-T2025-12-001', 'BMW Financial Services',    'CM', '2025-12-22', '2026-01-01', 120.00, 25.00),
('REG600000802', 'DL05000103', '5UXCR6C05NLL01501', 27, 'CT', 'LS', 'CT-AUT052', 'CT-T2026-01-001', 'BMW Financial Services',    'CM', '2026-01-26', '2026-02-05', 120.00, 25.00),
('REG600000803', 'DL05000105', 'WBY73AW05PFM01501', 29, 'CT', 'LS', 'CT-AUT053', 'CT-T2026-04-001', 'BMW Financial Services',    'IS', '2026-04-05', '2026-04-15', 120.00, 25.00),
('REG600000901', 'DL10000001', '4T1BF1FK5NU101001', 22, 'ID', 'NV', 'ID-AUT101', 'ID-T2026-01-001', 'Chase Auto Finance',        'CM', '2026-01-12', '2026-01-22', 48.00, 14.00),
('REG600000902', 'DL10000004', '2T3WFREV5NW201001', 25, 'ID', 'NV', 'ID-AUT102', 'ID-T2026-01-002', 'Ally Financial',            'CM', '2026-01-22', '2026-02-01', 48.00, 14.00),
('REG600000903', 'DL10000008', '5TDBKRFH5NS401001', 29, 'ID', 'NV', 'ID-AUT103', 'ID-T2026-01-003', 'Capital One Auto',          'CM', '2026-01-27', '2026-02-06', 48.00, 14.00),
('REG600001001', 'DL11000001', '1FTFW1E53NFA11002', 30, 'WI', 'NV', 'WI-AUT111', 'WI-T2026-02-001', 'Ally Financial',            'CM', '2026-02-26', '2026-03-08', 75.00, 69.50),
('REG600001002', 'DL11000005', '1FM5K8GC7PGA11301', 22, 'WI', 'NV', 'WI-AUT112', 'WI-T2026-03-001', 'Wells Fargo Dealer Svcs',   'CM', '2026-03-04', '2026-03-14', 75.00, 69.50),
('REG600001101', 'DL12000001', '7FARW2H93NE612001', 23, 'NY', 'NV', 'NY-AUT121', 'NY-T2026-02-001', 'Chase Auto Finance',        'CM', '2026-02-06', '2026-02-16', 26.00, 50.00),
('REG600001102', 'DL12000004', '5FNYF6H95NB812001', 26, 'NY', 'NV', 'NY-AUT122', 'NY-T2026-04-001', 'Wells Fargo Dealer Svcs',   'IS', '2026-04-10', '2026-04-20', 26.00, 50.00);
