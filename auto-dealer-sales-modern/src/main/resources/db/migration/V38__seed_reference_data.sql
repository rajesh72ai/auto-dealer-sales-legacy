-- V38__seed_reference_data.sql
-- Seed salesperson, lender, and price_schedule tables for complete demo coverage.

-- ── Salespersons (one per dealer + extras) ──────────────────────────
INSERT INTO salesperson (salesperson_id, salesperson_name, dealer_code, hire_date, commission_plan, active_flag) VALUES
('TSMITH01', 'Tom Smith',          'DLR01', '2022-03-15', 'ST', 'Y'),
('JDOE0001', 'Jessica Doe',        'DLR01', '2023-06-01', 'ST', 'Y'),
('DJONES02', 'Diana Jones',        'DLR02', '2021-09-10', 'SR', 'Y'),
('APARK002', 'Andrew Park',        'DLR02', '2024-01-15', 'ST', 'Y'),
('KLEE0003', 'Kevin Lee',          'DLR03', '2020-11-20', 'SR', 'Y'),
('LWONG003', 'Lisa Wong',          'DLR03', '2023-08-05', 'ST', 'Y'),
('MBROWN04', 'Mike Brown',         'DLR04', '2019-05-12', 'SR', 'Y'),
('RGREEN04', 'Rachel Green',       'DLR04', '2024-02-20', 'ST', 'Y'),
('PCHEN005', 'Peter Chen',         'DLR05', '2021-07-01', 'SR', 'Y'),
('SLEE0005', 'Samantha Lee',       'DLR05', '2023-11-10', 'ST', 'Y');

-- ── Lenders ─────────────────────────────────────────────────────────
INSERT INTO lender (lender_id, lender_name, contact_name, phone, address_line1, city, state_code, zip_code, lender_type, base_rate, spread, curtailment_days, free_floor_days, active_flag) VALUES
('ALLY1', 'Ally Financial',           'Sarah Mitchell',   '8003334636', '500 Woodward Ave',        'Detroit',      'MI', '48226', 'FP', 5.750, 1.250, 90,  30, 'Y'),
('CHASE', 'Chase Auto Finance',       'Michael Reynolds', '8002424210', '270 Park Avenue',         'New York',     'NY', '10017', 'FP', 5.500, 1.500, 90,  15, 'Y'),
('BMWFS', 'BMW Financial Services',   'Klaus Weber',      '8005784000', '300 Chestnut Ridge Rd',   'Woodcliff Lk', 'NJ', '07677', 'CP', 4.900, 0.750, 120, 45, 'Y'),
('CPTL1', 'Capital One Auto',         'David Park',       '8006895678', '1680 Capital One Dr',     'McLean',       'VA', '22102', 'RT', 6.250, 1.750, 60,  0,  'Y'),
('WELLS', 'Wells Fargo Dealer Svcs',  'Jennifer Adams',   '8005591355', '301 S College St',        'Charlotte',    'NC', '28288', 'RT', 5.900, 1.500, 90,  0,  'Y'),
('TDAFC', 'TD Auto Finance',          'Robert Miller',    '8007886262', '2035 Limestone Rd',       'Wilmington',   'DE', '19808', 'RT', 6.100, 1.250, 90,  0,  'Y');

-- ── Price Schedules (current + promotional) ─────────────────────────
INSERT INTO price_schedule (model_year, make_code, model_code, schedule_type, msrp, invoice_price, dealer_price, holdback_amt, destination_fee, effective_date, expiry_date, active_flag) VALUES
-- Ford F-150 XL
(2025, 'FRD', 'F150XL', 'ST', 42490.00, 38241.00, 37815.00, 1274.70, 1795.00, '2025-01-01', NULL, 'Y'),
(2025, 'FRD', 'F150XL', 'PR', 39990.00, 38241.00, 37815.00, 1274.70, 1795.00, '2026-03-01', '2026-03-31', 'Y'),
(2026, 'FRD', 'F150XL', 'ST', 43990.00, 39591.00, 39150.00, 1319.70, 1895.00, '2025-07-01', NULL, 'Y'),
-- Ford Escape SEL
(2025, 'FRD', 'ESCSEL', 'ST', 34500.00, 31050.00, 30700.00, 1035.00, 1495.00, '2025-01-01', NULL, 'Y'),
-- Ford Mustang GT
(2025, 'FRD', 'MUSTGT', 'ST', 42090.00, 37881.00, 37460.00, 1262.70, 1495.00, '2025-01-01', NULL, 'Y'),
-- Toyota Camry LE
(2025, 'TYT', 'CAMRYL', 'ST', 28855.00, 26825.00, 26540.00, 865.65,  1095.00, '2025-01-01', NULL, 'Y'),
(2026, 'TYT', 'CAMRYL', 'ST', 29500.00, 27425.00, 27130.00, 885.00,  1095.00, '2025-07-01', NULL, 'Y'),
-- Toyota RAV4 XLE Premium
(2025, 'TYT', 'RAV4XP', 'ST', 35535.00, 32335.00, 31990.00, 1066.05, 1335.00, '2025-01-01', NULL, 'Y'),
-- Toyota Tacoma SR5
(2025, 'TYT', 'TACSR5', 'ST', 35250.00, 31725.00, 31380.00, 1057.50, 1335.00, '2025-01-01', NULL, 'Y'),
-- Honda Civic EX
(2025, 'HND', 'CIVICX', 'ST', 27500.00, 24750.00, 24480.00, 825.00,  1095.00, '2025-01-01', NULL, 'Y'),
-- Honda CR-V EX-L
(2025, 'HND', 'CRV_EL', 'ST', 36600.00, 32940.00, 32580.00, 1098.00, 1295.00, '2025-01-01', NULL, 'Y'),
-- Honda Pilot Touring
(2025, 'HND', 'PILTEX', 'ST', 43050.00, 38745.00, 38320.00, 1291.50, 1495.00, '2025-01-01', NULL, 'Y'),
-- Chevy Silverado LT
(2025, 'CHV', 'SILVLT', 'ST', 44300.00, 39870.00, 39430.00, 1329.00, 1895.00, '2025-01-01', NULL, 'Y'),
-- Chevy Malibu LT
(2025, 'CHV', 'MALIBU', 'ST', 27290.00, 24561.00, 24290.00, 818.70,  1095.00, '2025-01-01', NULL, 'Y'),
-- BMW 330i xDrive
(2025, 'BMW', '330IXD', 'ST', 44900.00, 40410.00, 39960.00, 1347.00, 995.00,  '2025-01-01', NULL, 'Y'),
-- BMW X5 xDrive40i
(2025, 'BMW', 'X5XD40', 'ST', 65200.00, 58680.00, 58030.00, 1956.00, 995.00,  '2025-01-01', NULL, 'Y');
