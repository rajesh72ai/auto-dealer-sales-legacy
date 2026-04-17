-- ==========================================================================
-- V60: Expand to 12 dealers (DLR06-DLR12) for diverse AI Agent demo data
-- Each persona has 2 dealers. Brands diversified across dealers.
-- Persona cheatsheet:
--   DLR01/06 Volume leader | DLR02/07 Luxury | DLR03/08 Struggling
--   DLR04/09 Warranty hotspot | DLR05/10 F&I powerhouse | DLR11/12 Baseline
-- Pure INSERT only — no schema changes, no ALTER TABLE.
-- Parallel AI-table-changes session owns V45-V59. Future seed work: V67+.
-- ==========================================================================

-- ── New Dealers (DLR06-DLR12) ────────────────────────────────────────
INSERT INTO dealer (dealer_code, dealer_name, address_line1, city, state_code, zip_code, phone_number, fax_number, dealer_principal, region_code, zone_code, oem_dealer_num, floor_plan_lender_id, max_inventory, active_flag, opened_date) VALUES
('DLR06', 'Plainfield Ford',        '2100 Route 22 E',        'Plainfield',   'NJ', '07060', '9085556001', '9085556002', 'Anthony Russo',       'NES', 'E5', 'FRD0210001', 'ALLY1', 500, 'Y', '2008-05-12'),
('DLR07', 'Charlotte BMW',          '7020 Smith Corners Blvd','Charlotte',    'NC', '28269', '7045557001', '7045557002', 'Victoria Price',      'SES', 'E6', 'BMW0070020', 'BMWFS', 220, 'Y', '2014-02-28'),
('DLR08', 'Riverside Honda',        '8550 Indiana Ave',       'Riverside',    'CA', '92504', '9515558001', '9515558002', 'Daniel Fernandez',    'PSW', 'W4', 'HND0085500', 'CHASE', 380, 'Y', '2003-07-19'),
('DLR09', 'Dallas Chevrolet',       '4100 W Northwest Hwy',   'Dallas',       'TX', '75220', '2145559001', '2145559002', 'Christopher Bennett', 'SCS', 'S1', 'CHV0041001', 'CHASE', 480, 'Y', '1995-10-04'),
('DLR10', 'Boise Toyota',           '9200 W Fairview Ave',    'Boise',        'ID', '83704', '2085550101', '2085550102', 'Rebecca Larsen',      'MTN', 'W5', 'TYT0092001', 'ALLY1', 360, 'Y', '2011-08-22'),
('DLR11', 'Madison Ford',           '1600 Damon Rd',          'Madison',      'WI', '53704', '6085550201', '6085550202', 'Gregory Anderson',    'NCS', 'M1', 'FRD0160001', 'ALLY1', 400, 'Y', '2006-11-15'),
('DLR12', 'Albany Honda',           '800 Central Ave',        'Albany',       'NY', '12206', '5185550301', '5185550302', 'Michelle Rodriguez',  'NES', 'E7', 'HND0080001', 'CHASE', 380, 'Y', '2009-03-30');

-- ── Lot Locations (3 per new dealer) ────────────────────────────────
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES
('DLR06', 'SHOW01', 'Main Showroom',       'S', 14, 6),
('DLR06', 'FRNT01', 'Front Display Lot',   'F', 120, 58),
('DLR06', 'BACK01', 'Rear Overflow Lot',   'B', 250, 80),
('DLR07', 'SHOW01', 'Luxury Showroom',     'S', 10, 5),
('DLR07', 'FRNT01', 'Premium Display',     'F', 60, 28),
('DLR07', 'BACK01', 'Covered Storage',     'B', 80, 20),
('DLR08', 'SHOW01', 'Main Showroom',       'S', 10, 3),
('DLR08', 'FRNT01', 'Front Lot',           'F', 90, 52),
('DLR08', 'BACK01', 'Aged Inventory Lot',  'B', 180, 95),
('DLR09', 'SHOW01', 'Showroom',            'S', 14, 7),
('DLR09', 'FRNT01', 'Front Display',       'F', 110, 60),
('DLR09', 'BACK01', 'Back Lot',            'B', 200, 72),
('DLR10', 'SHOW01', 'Showroom Floor',      'S', 12, 5),
('DLR10', 'FRNT01', 'Front Lot',           'F', 90, 42),
('DLR10', 'OFFST1', 'Offsite Storage',     'O', 140, 30),
('DLR11', 'SHOW01', 'Main Showroom',       'S', 12, 5),
('DLR11', 'FRNT01', 'Front Display',       'F', 95, 44),
('DLR11', 'BACK01', 'Back Lot',            'B', 170, 50),
('DLR12', 'SHOW01', 'Main Showroom',       'S', 10, 4),
('DLR12', 'FRNT01', 'Front Lot',           'F', 85, 38),
('DLR12', 'BACK01', 'Back Lot',            'B', 150, 42);

-- ── Tax Rates for New States (NJ, NC, CA, TX, ID, WI, NY) ───────────
INSERT INTO tax_rate (state_code, county_code, city_code, state_rate, county_rate, city_rate, doc_fee_max, title_fee, reg_fee, effective_date) VALUES
('NJ', '00001', '00000', 0.0663, 0.0000, 0.0000, 499.00, 60.00, 46.00, '2025-01-01'),
('NC', '00001', '00000', 0.0475, 0.0200, 0.0050, 799.00, 14.00, 52.00, '2025-01-01'),
('CA', '00001', '00000', 0.0725, 0.0100, 0.0125, 85.00,  25.00, 88.00, '2025-01-01'),
('TX', '00001', '00000', 0.0625, 0.0100, 0.0050, 150.00, 28.00, 51.75, '2025-01-01'),
('ID', '00001', '00000', 0.0600, 0.0000, 0.0100, 399.00, 14.00, 48.00, '2025-01-01'),
('WI', '00001', '00000', 0.0500, 0.0055, 0.0000, 399.00, 69.50, 75.00, '2025-01-01'),
('NY', '00001', '00000', 0.0400, 0.0425, 0.0045, 175.00, 50.00, 26.00, '2025-01-01');

-- ── System Users (3 per new dealer: M=Manager, S=Salesperson, F=F&I) ─
-- Password hash for all: "password123"
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES
-- DLR06
('ARUSSO06', 'Anthony Russo',      '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR06', 'Y'),
('JSMITH06', 'Jeffrey Smith',      '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR06', 'Y'),
('MCHEN06',  'Melissa Chen',       '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR06', 'Y'),
-- DLR07
('VPRICE07', 'Victoria Price',     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR07', 'Y'),
('DGOLD07',  'Derek Goldstein',    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR07', 'Y'),
('RKAUR07',  'Rohini Kaur',        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR07', 'Y'),
-- DLR08
('DFERNA08', 'Daniel Fernandez',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR08', 'Y'),
('KSANT08',  'Karen Santos',       '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR08', 'Y'),
('BPATEL8',  'Bhavesh Patel',      '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR08', 'Y'),
-- DLR09
('CBENNT09', 'Christopher Bennett','$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR09', 'Y'),
('MJOHN09',  'Marcus Johnson',     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR09', 'Y'),
('DTAYL09',  'Dana Taylor',        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR09', 'Y'),
-- DLR10
('RLARSE10', 'Rebecca Larsen',     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR10', 'Y'),
('SMART10',  'Stephen Martinez',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR10', 'Y'),
('LKIM10',   'Lauren Kim',         '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR10', 'Y'),
-- DLR11
('GANDER11', 'Gregory Anderson',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR11', 'Y'),
('JWOOD11',  'Jessica Wood',       '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR11', 'Y'),
('NSINGH11', 'Neha Singh',         '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR11', 'Y'),
-- DLR12
('MRODRI12', 'Michelle Rodriguez', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR12', 'Y'),
('GLOPE12',  'Gabriela Lopez',     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR12', 'Y'),
('YGRAY12',  'Yolanda Gray',       '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR12', 'Y');

-- ── Salespersons (2 per new dealer — 1 matching user + 1 record-only) ─
INSERT INTO salesperson (salesperson_id, salesperson_name, dealer_code, hire_date, commission_plan, active_flag) VALUES
('JSMITH06', 'Jeffrey Smith',       'DLR06', '2020-06-15', 'SR', 'Y'),
('TBROWN06', 'Tanya Brown',         'DLR06', '2023-04-01', 'ST', 'Y'),
('DGOLD07',  'Derek Goldstein',     'DLR07', '2019-09-20', 'SR', 'Y'),
('CGREY07',  'Cassandra Grey',      'DLR07', '2022-11-15', 'SR', 'Y'),
('KSANT08',  'Karen Santos',        'DLR08', '2018-03-10', 'SR', 'Y'),
('TLOW08',   'Terrence Lowell',     'DLR08', '2024-08-22', 'ST', 'Y'),
('MJOHN09',  'Marcus Johnson',      'DLR09', '2017-05-08', 'SR', 'Y'),
('BFOSTER9', 'Brenda Foster',       'DLR09', '2023-01-12', 'ST', 'Y'),
('SMART10',  'Stephen Martinez',    'DLR10', '2021-02-18', 'SR', 'Y'),
('EYOUNG10', 'Ethan Young',         'DLR10', '2024-06-05', 'ST', 'Y'),
('JWOOD11',  'Jessica Wood',        'DLR11', '2019-10-25', 'SR', 'Y'),
('HKNIGH1',  'Harold Knight',       'DLR11', '2022-07-14', 'ST', 'Y'),
('GLOPE12',  'Gabriela Lopez',      'DLR12', '2020-12-01', 'SR', 'Y'),
('OWARD12',  'Olivia Ward',         'DLR12', '2024-03-18', 'ST', 'Y');

-- ── Aged Inventory Amplification for DLR03 (Struggling persona) ─────
-- 6 additional Honda vehicles with very old receive_dates (140-180 days)
-- These anchor the "aging inventory" signal for DLR03
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('19XFC1F38NE503001', 2025, 'HND', 'CIVICX', 'BLK', 'BLK', '2025-09-01', '2025-09-18', '2025-09-28', 'AV', 'DLR03', 'BACK01', 'H03-3001', 200, 'Y', '2025-09-29', 22),
('19XFC1F38NE503002', 2025, 'HND', 'CIVICX', 'GRY', 'TAN', '2025-09-20', '2025-10-05', '2025-10-15', 'AV', 'DLR03', 'BACK01', 'H03-3002', 183, 'Y', '2025-10-16', 18),
('7FARW2H93NE603001', 2025, 'HND', 'CRV_EL', 'WHT', 'GRY', '2025-09-10', '2025-09-28', '2025-10-08', 'AV', 'DLR03', 'BACK01', 'H03-3003', 190, 'Y', '2025-10-09', 25),
('7FARW2H93NE603002', 2025, 'HND', 'CRV_EL', 'RED', 'TAN', '2025-10-15', '2025-10-30', '2025-11-10', 'AV', 'DLR03', 'BACK01', 'H03-3004', 157, 'Y', '2025-11-11', 20),
('5FNYF6H95NB803001', 2025, 'HND', 'PILTEX', 'SLV', 'GRY', '2025-09-25', '2025-10-12', '2025-10-22', 'AV', 'DLR03', 'BACK01', 'H03-3005', 176, 'Y', '2025-10-23', 28),
('5FNYF6H95NB803002', 2025, 'HND', 'PILTEX', 'BLU', 'TAN', '2025-10-20', '2025-11-05', '2025-11-15', 'AV', 'DLR03', 'BACK01', 'H03-3006', 152, 'Y', '2025-11-16', 24);

-- ── Vehicles for DLR06 Plainfield Ford (Volume leader — 14 vehicles) ─
-- Mostly AV, fresh receive dates (last 30-75 days), F150 heavy
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('1FTFW1E53NFA06001', 2025, 'FRD', 'F150XL', 'WHT', 'BLK', '2025-12-20', '2026-01-08', '2026-01-18', 'AV', 'DLR06', 'FRNT01', 'F06-0101', 88,  'Y', '2026-01-19', 12),
('1FTFW1E53NFA06002', 2025, 'FRD', 'F150XL', 'BLK', 'GRY', '2026-01-15', '2026-02-01', '2026-02-10', 'AV', 'DLR06', 'FRNT01', 'F06-0102', 65,  'Y', '2026-02-11', 8),
('1FTFW1E53PFA06003', 2026, 'FRD', 'F150XL', 'BLU', 'BLK', '2026-02-10', '2026-02-25', '2026-03-05', 'AV', 'DLR06', 'SHOW01', 'F06-0103', 42,  'Y', '2026-03-06', 5),
('1FTFW1E53PFA06004', 2026, 'FRD', 'F150XL', 'RED', 'GRY', '2026-02-25', '2026-03-12', '2026-03-22', 'AV', 'DLR06', 'FRNT01', 'F06-0104', 25,  'Y', '2026-03-23', 4),
('1FTFW1E53PFA06005', 2026, 'FRD', 'F150XL', 'SLV', 'BLK', '2026-03-15', '2026-03-28', '2026-04-05', 'AV', 'DLR06', 'FRNT01', 'F06-0105', 11,  'Y', '2026-04-06', 3),
('1FMCU9J93NUA06101', 2025, 'FRD', 'ESCSEL', 'WHT', 'BLK', '2025-12-10', '2025-12-28', '2026-01-08', 'SD', 'DLR06', NULL,     'F06-0201', 98,  'Y', '2026-01-09', 14),
('1FMCU9J93NUA06102', 2025, 'FRD', 'ESCSEL', 'BLU', 'TAN', '2026-01-20', '2026-02-05', '2026-02-15', 'AV', 'DLR06', 'FRNT01', 'F06-0202', 60,  'Y', '2026-02-16', 9),
('1FMCU9J93NUA06103', 2025, 'FRD', 'ESCSEL', 'RED', 'BLK', '2026-02-28', '2026-03-14', '2026-03-24', 'AV', 'DLR06', 'FRNT01', 'F06-0203', 23,  'Y', '2026-03-25', 6),
('1FA6P8CF7N5A06201', 2025, 'FRD', 'MUSTGT', 'RED', 'BLK', '2026-01-05', '2026-01-22', '2026-02-01', 'AV', 'DLR06', 'SHOW01', 'F06-0301', 74,  'Y', '2026-02-02', 10),
('1FA6P8CF7N5A06202', 2025, 'FRD', 'MUSTGT', 'BLK', 'RED', '2026-02-18', '2026-03-04', '2026-03-14', 'SD', 'DLR06', NULL,     'F06-0302', 33,  'Y', '2026-03-15', 7),
('1FM5K8GC7PGA06301', 2026, 'FRD', 'EXPLLT', 'GRN', 'TAN', '2026-02-05', '2026-02-20', '2026-03-02', 'AV', 'DLR06', 'SHOW01', 'F06-0401', 45,  'Y', '2026-03-03', 5),
('1FM5K8GC7PGA06302', 2026, 'FRD', 'EXPLLT', 'WHT', 'BLK', '2026-03-05', '2026-03-20', '2026-03-30', 'AV', 'DLR06', 'FRNT01', 'F06-0402', 17,  'Y', '2026-03-31', 4),
('1FTFW1E53PFA06006', 2026, 'FRD', 'F150XL', 'GRY', 'BLK', '2026-03-25', '2026-04-08', NULL,         'IT', 'DLR06', NULL,     'F06-0106', 0,   'N', NULL,         0),
('1FM5K8GC7PGA06303', 2026, 'FRD', 'EXPLLT', 'BLU', 'TAN', '2026-03-30', NULL,         NULL,         'AL', 'DLR06', NULL,     'F06-0403', 0,   'N', NULL,         0);

-- ── Vehicles for DLR07 Charlotte BMW (Luxury — 8 vehicles) ──────────
-- High-value BMW mix, moderate age, one aged unit
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('WBA5R1C50NFJ07001', 2025, 'BMW', '330IXD', 'BLK', 'BLK', '2025-11-10', '2025-12-05', '2025-12-18', 'AV', 'DLR07', 'SHOW01', 'B07-0101', 120, 'Y', '2025-12-19', 18),
('WBA5R1C50NFJ07002', 2025, 'BMW', '330IXD', 'WHT', 'TAN', '2026-01-15', '2026-02-05', '2026-02-18', 'AV', 'DLR07', 'FRNT01', 'B07-0102', 57,  'Y', '2026-02-19', 9),
('5UXCR6C05NLL07001', 2025, 'BMW', 'X5XD40', 'BLU', 'TAN', '2025-12-05', '2025-12-28', '2026-01-10', 'SD', 'DLR07', NULL,     'B07-0201', 96,  'Y', '2026-01-11', 14),
('5UXCR6C05NLL07002', 2025, 'BMW', 'X5XD40', 'BLK', 'BLK', '2026-01-25', '2026-02-15', '2026-02-28', 'AV', 'DLR07', 'SHOW01', 'B07-0202', 47,  'Y', '2026-03-01', 7),
('5UXCR6C05NLL07003', 2025, 'BMW', 'X5XD40', 'SLV', 'TAN', '2026-02-28', '2026-03-20', '2026-04-02', 'AV', 'DLR07', 'FRNT01', 'B07-0203', 14,  'Y', '2026-04-03', 4),
('WBY73AW05PFM07001', 2026, 'BMW', 'IX_50E', 'GRY', 'BLK', '2026-01-20', '2026-02-10', '2026-02-25', 'AV', 'DLR07', 'SHOW01', 'B07-0301', 50,  'Y', '2026-02-26', 6),
('WBY73AW05PFM07002', 2026, 'BMW', 'IX_50E', 'BLK', 'TAN', '2026-03-01', '2026-03-22', '2026-04-04', 'AV', 'DLR07', 'SHOW01', 'B07-0302', 12,  'Y', '2026-04-05', 3),
('WBA5R1C50NFJ07003', 2025, 'BMW', '330IXD', 'BLU', 'TAN', '2025-09-15', '2025-10-10', '2025-10-22', 'AV', 'DLR07', 'BACK01', 'B07-0103', 177, 'Y', '2025-10-23', 15);

-- ── Vehicles for DLR08 Riverside Honda (Struggling — 12 vehicles, many aged) ─
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('19XFC1F38NE508001', 2025, 'HND', 'CIVICX', 'BLU', 'BLK', '2025-08-15', '2025-09-05', '2025-09-15', 'AV', 'DLR08', 'BACK01', 'H08-0101', 213, 'Y', '2025-09-16', 28),
('19XFC1F38NE508002', 2025, 'HND', 'CIVICX', 'WHT', 'GRY', '2025-09-10', '2025-09-28', '2025-10-08', 'AV', 'DLR08', 'BACK01', 'H08-0102', 190, 'Y', '2025-10-09', 24),
('19XFC1F38NE508003', 2025, 'HND', 'CIVICX', 'RED', 'BLK', '2025-10-05', '2025-10-25', '2025-11-05', 'AV', 'DLR08', 'BACK01', 'H08-0103', 162, 'Y', '2025-11-06', 19),
('7FARW2H93NE608001', 2025, 'HND', 'CRV_EL', 'GRY', 'BLK', '2025-08-20', '2025-09-10', '2025-09-22', 'AV', 'DLR08', 'BACK01', 'H08-0201', 206, 'Y', '2025-09-23', 30),
('7FARW2H93NE608002', 2025, 'HND', 'CRV_EL', 'WHT', 'TAN', '2025-09-25', '2025-10-15', '2025-10-25', 'AV', 'DLR08', 'BACK01', 'H08-0202', 173, 'Y', '2025-10-26', 22),
('7FARW2H93NE608003', 2025, 'HND', 'CRV_EL', 'BLK', 'BLK', '2025-11-01', '2025-11-20', '2025-11-30', 'AV', 'DLR08', 'FRNT01', 'H08-0203', 137, 'Y', '2025-12-01', 16),
('1HGCV3F16PA708001', 2026, 'HND', 'ACCORD', 'BLK', 'BLK', '2025-12-10', '2025-12-28', '2026-01-08', 'AV', 'DLR08', 'FRNT01', 'H08-0301', 98,  'Y', '2026-01-09', 12),
('1HGCV3F16PA708002', 2026, 'HND', 'ACCORD', 'WHT', 'GRY', '2026-01-15', '2026-02-02', '2026-02-12', 'AV', 'DLR08', 'FRNT01', 'H08-0302', 63,  'Y', '2026-02-13', 8),
('5FNYF6H95NB808001', 2025, 'HND', 'PILTEX', 'SLV', 'BLK', '2025-09-05', '2025-09-22', '2025-10-02', 'AV', 'DLR08', 'BACK01', 'H08-0401', 196, 'Y', '2025-10-03', 26),
('5FNYF6H95NB808002', 2025, 'HND', 'PILTEX', 'WHT', 'TAN', '2025-10-25', '2025-11-12', '2025-11-22', 'AV', 'DLR08', 'BACK01', 'H08-0402', 145, 'Y', '2025-11-23', 18),
('19XFC1F38NE508004', 2025, 'HND', 'CIVICX', 'SLV', 'BLK', '2025-07-10', '2025-07-30', '2025-08-10', 'SD', 'DLR08', NULL,     'H08-0104', 249, 'Y', '2025-08-11', 35),
('7FARW2H93NE608004', 2025, 'HND', 'CRV_EL', 'BLU', 'BLK', '2026-02-01', '2026-02-20', '2026-03-02', 'AV', 'DLR08', 'FRNT01', 'H08-0204', 45,  'Y', '2026-03-03', 6);

-- ── Vehicles for DLR09 Dallas Chevrolet (Warranty hotspot — 10 vehicles) ──
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('1GCUYEED5NZ909001', 2025, 'CHV', 'SILVLT', 'WHT', 'BLK', '2025-11-15', '2025-12-02', '2025-12-12', 'SD', 'DLR09', NULL,     'C09-0101', 125, 'Y', '2025-12-13', 16),
('1GCUYEED5NZ909002', 2025, 'CHV', 'SILVLT', 'BLK', 'GRY', '2025-12-20', '2026-01-08', '2026-01-18', 'AV', 'DLR09', 'FRNT01', 'C09-0102', 88,  'Y', '2026-01-19', 11),
('1GCUYEED5NZ909003', 2025, 'CHV', 'SILVLT', 'RED', 'BLK', '2026-01-25', '2026-02-12', '2026-02-22', 'AV', 'DLR09', 'FRNT01', 'C09-0103', 53,  'Y', '2026-02-23', 7),
('1GCUYEED5NZ909004', 2025, 'CHV', 'SILVLT', 'GRY', 'BLK', '2026-02-25', '2026-03-14', '2026-03-24', 'AV', 'DLR09', 'FRNT01', 'C09-0104', 23,  'Y', '2026-03-25', 4),
('3GNAXKEV0PS109001', 2026, 'CHV', 'EQNOLT', 'BLU', 'GRY', '2025-12-10', '2025-12-28', '2026-01-08', 'SD', 'DLR09', NULL,     'C09-0201', 98,  'Y', '2026-01-09', 13),
('3GNAXKEV0PS109002', 2026, 'CHV', 'EQNOLT', 'WHT', 'BLK', '2026-01-20', '2026-02-05', '2026-02-15', 'AV', 'DLR09', 'SHOW01', 'C09-0202', 60,  'Y', '2026-02-16', 8),
('3GNAXKEV0PS109003', 2026, 'CHV', 'EQNOLT', 'RED', 'BLK', '2026-02-25', '2026-03-14', '2026-03-24', 'AV', 'DLR09', 'FRNT01', 'C09-0203', 23,  'Y', '2026-03-25', 5),
('1G1ZD5STXNF209001', 2025, 'CHV', 'MALIBU', 'SLV', 'BLK', '2025-11-20', '2025-12-10', '2025-12-20', 'AV', 'DLR09', 'FRNT01', 'C09-0301', 117, 'Y', '2025-12-21', 15),
('1G1ZD5STXNF209002', 2025, 'CHV', 'MALIBU', 'BLK', 'GRY', '2026-01-15', '2026-02-02', '2026-02-12', 'AV', 'DLR09', 'FRNT01', 'C09-0302', 63,  'Y', '2026-02-13', 9),
('1G1ZD5STXNF209003', 2025, 'CHV', 'MALIBU', 'WHT', 'TAN', '2026-03-05', '2026-03-22', '2026-04-02', 'AV', 'DLR09', 'SHOW01', 'C09-0303', 14,  'Y', '2026-04-03', 4);

-- ── Vehicles for DLR10 Boise Toyota (F&I powerhouse — 10 vehicles) ──
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('4T1BF1FK5NU101001', 2025, 'TYT', 'CAMRYL', 'WHT', 'BLK', '2025-12-05', '2025-12-25', '2026-01-05', 'SD', 'DLR10', NULL,     'T10-0101', 101, 'Y', '2026-01-06', 13),
('4T1BF1FK5PU201001', 2026, 'TYT', 'CAMRYL', 'SLV', 'GRY', '2026-01-20', '2026-02-08', '2026-02-18', 'AV', 'DLR10', 'SHOW01', 'T10-0201', 57,  'Y', '2026-02-19', 8),
('4T1BF1FK5PU201002', 2026, 'TYT', 'CAMRYL', 'BLK', 'BLK', '2026-02-28', '2026-03-18', '2026-03-28', 'AV', 'DLR10', 'FRNT01', 'T10-0202', 19,  'Y', '2026-03-29', 4),
('2T3WFREV5NW201001', 2025, 'TYT', 'RAV4XP', 'BLU', 'BLK', '2025-12-15', '2026-01-05', '2026-01-15', 'SD', 'DLR10', NULL,     'T10-0301', 91,  'Y', '2026-01-16', 15),
('2T3WFREV5NW201002', 2025, 'TYT', 'RAV4XP', 'RED', 'TAN', '2026-01-25', '2026-02-12', '2026-02-22', 'AV', 'DLR10', 'FRNT01', 'T10-0302', 53,  'Y', '2026-02-23', 8),
('3TMCZ5AN5NM301001', 2025, 'TYT', 'TACSR5', 'GRY', 'BLK', '2026-01-10', '2026-01-28', '2026-02-08', 'AV', 'DLR10', 'FRNT01', 'T10-0401', 67,  'Y', '2026-02-09', 10),
('3TMCZ5AN5NM301002', 2025, 'TYT', 'TACSR5', 'WHT', 'GRY', '2026-02-20', '2026-03-08', '2026-03-18', 'AV', 'DLR10', 'FRNT01', 'T10-0402', 29,  'Y', '2026-03-19', 5),
('5TDBKRFH5NS401001', 2025, 'TYT', 'HGHLXL', 'BLK', 'TAN', '2025-12-20', '2026-01-10', '2026-01-20', 'SD', 'DLR10', NULL,     'T10-0501', 86,  'Y', '2026-01-21', 14),
('5TDBKRFH5NS401002', 2025, 'TYT', 'HGHLXL', 'WHT', 'BLK', '2026-02-05', '2026-02-22', '2026-03-04', 'AV', 'DLR10', 'SHOW01', 'T10-0502', 43,  'Y', '2026-03-05', 6),
('2T3WFREV5NW201003', 2025, 'TYT', 'RAV4XP', 'GRN', 'BLK', '2026-03-10', '2026-03-28', NULL,         'IT', 'DLR10', NULL,     'T10-0303', 0,   'N', NULL,         0);

-- ── Vehicles for DLR11 Madison Ford (Baseline — 8 vehicles) ─────────
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('1FTFW1E53NFA11001', 2025, 'FRD', 'F150XL', 'WHT', 'BLK', '2025-12-15', '2026-01-05', '2026-01-15', 'AV', 'DLR11', 'FRNT01', 'F11-0101', 91,  'Y', '2026-01-16', 12),
('1FTFW1E53NFA11002', 2025, 'FRD', 'F150XL', 'BLK', 'GRY', '2026-01-20', '2026-02-08', '2026-02-18', 'SD', 'DLR11', NULL,     'F11-0102', 57,  'Y', '2026-02-19', 9),
('1FTFW1E53PFA11003', 2026, 'FRD', 'F150XL', 'BLU', 'BLK', '2026-02-25', '2026-03-14', '2026-03-24', 'AV', 'DLR11', 'FRNT01', 'F11-0103', 23,  'Y', '2026-03-25', 4),
('1FMCU9J93NUA11101', 2025, 'FRD', 'ESCSEL', 'WHT', 'BLK', '2026-01-05', '2026-01-24', '2026-02-03', 'AV', 'DLR11', 'FRNT01', 'F11-0201', 72,  'Y', '2026-02-04', 10),
('1FMCU9J93NUA11102', 2025, 'FRD', 'ESCSEL', 'RED', 'TAN', '2026-02-28', '2026-03-18', '2026-03-28', 'AV', 'DLR11', 'SHOW01', 'F11-0202', 19,  'Y', '2026-03-29', 5),
('1FA6P8CF7N5A11201', 2025, 'FRD', 'MUSTGT', 'BLK', 'RED', '2026-02-10', '2026-02-28', '2026-03-10', 'AV', 'DLR11', 'SHOW01', 'F11-0301', 37,  'Y', '2026-03-11', 6),
('1FM5K8GC7PGA11301', 2026, 'FRD', 'EXPLLT', 'GRN', 'TAN', '2026-01-25', '2026-02-15', '2026-02-25', 'AV', 'DLR11', 'SHOW01', 'F11-0401', 50,  'Y', '2026-02-26', 7),
('1FM5K8GC7PGA11302', 2026, 'FRD', 'EXPLLT', 'WHT', 'BLK', '2026-03-15', '2026-04-02', NULL,         'IT', 'DLR11', NULL,     'F11-0402', 0,   'N', NULL,         0);

-- ── Vehicles for DLR12 Albany Honda (Baseline — 8 vehicles) ─────────
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
('19XFC1F38NE512001', 2025, 'HND', 'CIVICX', 'BLU', 'BLK', '2025-12-20', '2026-01-08', '2026-01-18', 'AV', 'DLR12', 'FRNT01', 'H12-0101', 88,  'Y', '2026-01-19', 11),
('19XFC1F38NE512002', 2025, 'HND', 'CIVICX', 'WHT', 'GRY', '2026-02-10', '2026-02-28', '2026-03-10', 'AV', 'DLR12', 'FRNT01', 'H12-0102', 37,  'Y', '2026-03-11', 6),
('7FARW2H93NE612001', 2025, 'HND', 'CRV_EL', 'GRY', 'BLK', '2026-01-05', '2026-01-22', '2026-02-01', 'SD', 'DLR12', NULL,     'H12-0201', 74,  'Y', '2026-02-02', 11),
('7FARW2H93NE612002', 2025, 'HND', 'CRV_EL', 'WHT', 'TAN', '2026-02-20', '2026-03-08', '2026-03-18', 'AV', 'DLR12', 'SHOW01', 'H12-0202', 29,  'Y', '2026-03-19', 5),
('1HGCV3F16PA712001', 2026, 'HND', 'ACCORD', 'BLK', 'BLK', '2026-01-25', '2026-02-12', '2026-02-22', 'AV', 'DLR12', 'SHOW01', 'H12-0301', 53,  'Y', '2026-02-23', 8),
('1HGCV3F16PA712002', 2026, 'HND', 'ACCORD', 'WHT', 'GRY', '2026-03-08', '2026-03-24', '2026-04-03', 'AV', 'DLR12', 'FRNT01', 'H12-0302', 13,  'Y', '2026-04-04', 3),
('5FNYF6H95NB812001', 2025, 'HND', 'PILTEX', 'SLV', 'BLK', '2026-01-15', '2026-02-02', '2026-02-12', 'AV', 'DLR12', 'FRNT01', 'H12-0401', 63,  'Y', '2026-02-13', 9),
('5FNYF6H95NB812002', 2025, 'HND', 'PILTEX', 'RED', 'TAN', '2026-03-10', '2026-03-28', NULL,         'IT', 'DLR12', NULL,     'H12-0402', 0,   'N', NULL,         0);
