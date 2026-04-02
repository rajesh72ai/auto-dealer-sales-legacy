-- V33: Seed warranty claims across all dealers
-- Claim types: BA (Basic), PT (Powertrain), EX (Extended), GW (Goodwill), RC (Recall), PD (Pre-Delivery)
-- Claim statuses: NW, IP, AP, PA, PD, DN, CL

INSERT INTO warranty_claim (claim_number, vin, dealer_code, claim_type, claim_date, repair_date, labor_amt, parts_amt, total_claim, claim_status, technician_id, repair_order_num, notes) VALUES
-- DLR01 claims
('WC000001', '1FMCU9J93NUA00301', 'DLR01', 'BA', '2025-08-10', '2025-08-12', 185.00, 342.50, 527.50, 'PD', 'TECH0101', 'RO-DLR01-001', 'Replaced faulty blend door actuator under basic warranty'),
('WC000002', '1FA6P8CF7N5A00401', 'DLR01', 'PT', '2025-09-05', '2025-09-08', 420.00, 1285.00, 1705.00, 'AP', 'TECH0102', 'RO-DLR01-002', 'Transmission shudder at highway speeds, torque converter replaced'),
('WC000003', '1FTFW1E53NFA00101', 'DLR01', 'PD', '2025-07-02', '2025-07-03', 65.00, 28.00, 93.00, 'CL', 'TECH0101', 'RO-DLR01-003', 'PDI correction: misaligned hood latch, adjusted and tested'),

-- DLR02 claims
('WC000004', '4T1BF1FK5NU100101', 'DLR02', 'BA', '2025-08-20', '2025-08-22', 145.00, 189.00, 334.00, 'PD', 'TECH0201', 'RO-DLR02-001', 'Squeaking brake pads at low speed, pads and rotors replaced'),
('WC000005', '2T3WFREV5NW200202', 'DLR02', 'EX', '2025-09-15', NULL, 310.00, 875.00, 1185.00, 'IP', 'TECH0202', 'RO-DLR02-002', 'Infotainment screen flickering, awaiting replacement display unit'),
('WC000006', '3TMCZ5AN5NM300101', 'DLR02', 'GW', '2025-09-01', '2025-09-03', 95.00, 125.00, 220.00, 'AP', 'TECH0201', 'RO-DLR02-003', 'Goodwill repair: minor paint bubble on rear quarter panel'),

-- DLR03 claims
('WC000007', '19XFC1F38NE500101', 'DLR03', 'BA', '2025-09-10', '2025-09-12', 175.00, 410.00, 585.00, 'PD', 'TECH0301', 'RO-DLR03-001', 'AC compressor bearing noise, compressor assembly replaced'),
('WC000008', '7FARW2H93NE600101', 'DLR03', 'RC', '2025-09-20', NULL, 0.00, 0.00, 0.00, 'NW', 'TECH0302', 'RO-DLR03-002', 'Recall campaign: fuel pump control module software update pending'),
('WC000009', '5FNYF6H95NB800101', 'DLR03', 'PT', '2025-07-15', '2025-07-18', 550.00, 2100.00, 2650.00, 'PD', 'TECH0301', 'RO-DLR03-003', 'Engine oil consumption issue, piston rings replaced under PT warranty'),

-- DLR04 claims
('WC000010', '1GCUYEED5NZ900101', 'DLR04', 'BA', '2025-08-25', '2025-08-27', 210.00, 565.00, 775.00, 'PD', 'TECH0401', 'RO-DLR04-001', 'Power window regulator failure driver side, replaced motor and track'),
('WC000011', '1G1ZD5STXNF200101', 'DLR04', 'EX', '2025-09-28', NULL, 280.00, 450.00, 730.00, 'NW', 'TECH0402', 'RO-DLR04-002', 'Rear camera intermittent black screen, diagnostic pending'),
('WC000012', '3GNAXKEV0PS100101', 'DLR04', 'BA', '2025-09-22', '2025-09-25', 125.00, 78.00, 203.00, 'DN', 'TECH0401', 'RO-DLR04-003', 'Door handle sticky, customer modification voids warranty coverage'),

-- DLR05 claims
('WC000013', 'WBA5R1C50NFJ00101', 'DLR05', 'BA', '2025-07-20', '2025-07-22', 350.00, 890.00, 1240.00, 'PD', 'TECH0501', 'RO-DLR05-001', 'Adaptive cruise control sensor malfunction, replaced radar module'),
('WC000014', '5UXCR6C05NLL00201', 'DLR05', 'PT', '2025-09-18', '2025-09-22', 475.00, 1650.00, 2125.00, 'AP', 'TECH0502', 'RO-DLR05-002', 'Transfer case whine at low speed, replaced transfer case assembly'),
('WC000015', 'WBA5R1C50NFJ00104', 'DLR05', 'GW', '2025-09-25', NULL, 150.00, 320.00, 470.00, 'PA', 'TECH0501', 'RO-DLR05-003', 'Goodwill: interior trim rattle, partial approval for labor only');
