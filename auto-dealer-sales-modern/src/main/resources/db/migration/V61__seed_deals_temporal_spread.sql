-- ==========================================================================
-- V61: 75 new deals with temporal spread (2025-05 to 2026-04-16)
-- ~60% of deals land in the last 90 days so "morning briefing" / "deals this
-- week" queries return meaningful data.
-- Persona differentiation via front/back gross and deal count per dealer.
-- Supplemental vehicles added at top to back new deals (existing V17 vehicles
-- are already consumed by V19/V32 deals).
-- ==========================================================================

-- ── Supplemental vehicles for existing dealers (to back V61 deals) ──
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
-- DLR01 supplement (10 — volume leader)
('1FTFW1E53NFA01501', 2025, 'FRD', 'F150XL', 'WHT', 'BLK', '2025-10-15', '2025-11-02', '2025-11-12', 'SD', 'DLR01', NULL, 'F01-1501', 152, 'Y', '2025-11-13', 14),
('1FTFW1E53NFA01502', 2025, 'FRD', 'F150XL', 'BLK', 'GRY', '2025-11-20', '2025-12-08', '2025-12-18', 'SD', 'DLR01', NULL, 'F01-1502', 118, 'Y', '2025-12-19', 11),
('1FTFW1E53PFA01503', 2026, 'FRD', 'F150XL', 'RED', 'BLK', '2026-01-10', '2026-01-28', '2026-02-07', 'SD', 'DLR01', NULL, 'F01-1503', 68,  'Y', '2026-02-08', 9),
('1FTFW1E53PFA01504', 2026, 'FRD', 'F150XL', 'BLU', 'GRY', '2026-02-15', '2026-03-05', '2026-03-15', 'SD', 'DLR01', NULL, 'F01-1504', 32,  'Y', '2026-03-16', 5),
('1FMCU9J93NUA01501', 2025, 'FRD', 'ESCSEL', 'WHT', 'BLK', '2025-12-05', '2025-12-22', '2026-01-01', 'SD', 'DLR01', NULL, 'F01-1601', 105, 'Y', '2026-01-02', 10),
('1FMCU9J93NUA01502', 2025, 'FRD', 'ESCSEL', 'BLU', 'TAN', '2026-02-20', '2026-03-10', '2026-03-20', 'SD', 'DLR01', NULL, 'F01-1602', 27,  'Y', '2026-03-21', 4),
('1FA6P8CF7N5A01501', 2025, 'FRD', 'MUSTGT', 'RED', 'BLK', '2026-01-15', '2026-02-02', '2026-02-12', 'SD', 'DLR01', NULL, 'F01-1701', 63,  'Y', '2026-02-13', 7),
('1FM5K8GC7PGA01501', 2026, 'FRD', 'EXPLLT', 'GRN', 'TAN', '2026-02-28', '2026-03-18', '2026-03-28', 'SD', 'DLR01', NULL, 'F01-1801', 19,  'Y', '2026-03-29', 4),
('1FM5K8GC7PGA01502', 2026, 'FRD', 'EXPLLT', 'WHT', 'BLK', '2026-03-20', '2026-04-05', '2026-04-12', 'SD', 'DLR01', NULL, 'F01-1802', 4,   'Y', '2026-04-13', 2),
('1FTFW1E53PFA01505', 2026, 'FRD', 'F150XL', 'SLV', 'GRY', '2026-04-01', '2026-04-10', '2026-04-14', 'SD', 'DLR01', NULL, 'F01-1505', 2,   'Y', '2026-04-15', 2),
-- DLR02 supplement (5 — luxury)
('4T1BF1FK5PU201501', 2026, 'TYT', 'CAMRYL', 'WHT', 'BLK', '2026-01-10', '2026-01-28', '2026-02-07', 'SD', 'DLR02', NULL, 'T02-1501', 68,  'Y', '2026-02-08', 8),
('5TDBKRFH5NS401501', 2025, 'TYT', 'HGHLXL', 'BLK', 'TAN', '2025-11-20', '2025-12-10', '2025-12-20', 'SD', 'DLR02', NULL, 'T02-1601', 116, 'Y', '2025-12-21', 13),
('5TDBKRFH5NS401502', 2025, 'TYT', 'HGHLXL', 'WHT', 'TAN', '2026-02-10', '2026-03-01', '2026-03-11', 'SD', 'DLR02', NULL, 'T02-1602', 36,  'Y', '2026-03-12', 5),
('5TDBKRFH5NS401503', 2025, 'TYT', 'HGHLXL', 'SLV', 'BLK', '2026-03-15', '2026-04-02', '2026-04-10', 'SD', 'DLR02', NULL, 'T02-1603', 6,   'Y', '2026-04-11', 3),
('2T3WFREV5NW201501', 2025, 'TYT', 'RAV4XP', 'BLU', 'BLK', '2026-03-25', '2026-04-08', '2026-04-14', 'SD', 'DLR02', NULL, 'T02-1701', 2,   'Y', '2026-04-15', 2),
-- DLR03 supplement (3 — struggling, old dates)
('19XFC1F38NE501501', 2025, 'HND', 'CIVICX', 'WHT', 'GRY', '2025-06-10', '2025-06-28', '2025-07-08', 'SD', 'DLR03', NULL, 'H03-1501', 282, 'Y', '2025-07-09', 18),
('7FARW2H93NE601501', 2025, 'HND', 'CRV_EL', 'RED', 'TAN', '2025-08-20', '2025-09-10', '2025-09-20', 'SD', 'DLR03', NULL, 'H03-1601', 208, 'Y', '2025-09-21', 22),
('1HGCV3F16PA701501', 2026, 'HND', 'ACCORD', 'BLU', 'BLK', '2026-02-15', '2026-03-05', '2026-03-15', 'SD', 'DLR03', NULL, 'H03-1701', 32,  'Y', '2026-03-16', 5),
-- DLR04 supplement (6 — warranty hotspot)
('1GCUYEED5NZ901501', 2025, 'CHV', 'SILVLT', 'BLU', 'GRY', '2025-10-20', '2025-11-08', '2025-11-18', 'SD', 'DLR04', NULL, 'C04-1501', 149, 'Y', '2025-11-19', 15),
('1GCUYEED5NZ901502', 2025, 'CHV', 'SILVLT', 'GRY', 'BLK', '2025-12-10', '2025-12-28', '2026-01-07', 'SD', 'DLR04', NULL, 'C04-1502', 99,  'Y', '2026-01-08', 11),
('3GNAXKEV0PS101501', 2026, 'CHV', 'EQNOLT', 'WHT', 'GRY', '2026-01-20', '2026-02-05', '2026-02-15', 'SD', 'DLR04', NULL, 'C04-1601', 60,  'Y', '2026-02-16', 7),
('3GNAXKEV0PS101502', 2026, 'CHV', 'EQNOLT', 'BLK', 'BLK', '2026-02-25', '2026-03-14', '2026-03-24', 'SD', 'DLR04', NULL, 'C04-1602', 23,  'Y', '2026-03-25', 4),
('1G1ZD5STXNF201501', 2025, 'CHV', 'MALIBU', 'RED', 'BLK', '2026-03-05', '2026-03-22', '2026-04-01', 'SD', 'DLR04', NULL, 'C04-1701', 15,  'Y', '2026-04-02', 3),
('1G1ZD5STXNF201502', 2025, 'CHV', 'MALIBU', 'SLV', 'BLK', '2026-03-25', '2026-04-08', '2026-04-14', 'SD', 'DLR04', NULL, 'C04-1702', 2,   'Y', '2026-04-15', 2),
-- DLR05 supplement (6 — F&I powerhouse, BMW premium)
('WBA5R1C50NFJ01501', 2025, 'BMW', '330IXD', 'BLK', 'BLK', '2025-11-10', '2025-12-02', '2025-12-15', 'SD', 'DLR05', NULL, 'B05-1501', 122, 'Y', '2025-12-16', 12),
('WBA5R1C50NFJ01502', 2025, 'BMW', '330IXD', 'WHT', 'TAN', '2026-01-25', '2026-02-15', '2026-02-28', 'SD', 'DLR05', NULL, 'B05-1502', 47,  'Y', '2026-03-01', 7),
('5UXCR6C05NLL01501', 2025, 'BMW', 'X5XD40', 'BLU', 'TAN', '2025-12-15', '2026-01-05', '2026-01-18', 'SD', 'DLR05', NULL, 'B05-1601', 88,  'Y', '2026-01-19', 10),
('5UXCR6C05NLL01502', 2025, 'BMW', 'X5XD40', 'BLK', 'BLK', '2026-02-10', '2026-03-02', '2026-03-14', 'SD', 'DLR05', NULL, 'B05-1602', 33,  'Y', '2026-03-15', 5),
('WBY73AW05PFM01501', 2026, 'BMW', 'IX_50E', 'GRY', 'BLK', '2026-02-25', '2026-03-15', '2026-03-28', 'SD', 'DLR05', NULL, 'B05-1701', 19,  'Y', '2026-03-29', 4),
('WBY73AW05PFM01502', 2026, 'BMW', 'IX_50E', 'WHT', 'TAN', '2026-03-15', '2026-04-02', '2026-04-12', 'SD', 'DLR05', NULL, 'B05-1702', 4,   'Y', '2026-04-13', 2);

-- ── Deals — DLR01 Lakewood Ford (Volume leader — 10 new deals) ──────
-- Healthy front gross ($1,800-$3,000), moderate back gross ($800-$1,500)
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL01000101', 'DLR01', 1, '1FTFW1E53NFA01501', 'TSMITH01', 'JPATTER1', 'R', 'DL', 44970.00, 1895.00, 46865.00, 799.00, 1359.09, 468.65, 7.20, 50.00, 49549.94, 8000.00, 41549.94, 2248.50, 1150.00, 3398.50, '2025-11-15', '2025-11-18'),
('DL01000102', 'DLR01', 2, '1FTFW1E53NFA01502', 'TSMITH01', 'JPATTER1', 'R', 'DL', 44970.00, 1895.00, 46865.00, 799.00, 1359.09, 468.65, 7.20, 50.00, 49549.94, 10000.00, 39549.94, 2698.00, 1325.00, 4023.00, '2025-12-22', '2025-12-27'),
('DL01000103', 'DLR01', 3, '1FTFW1E53PFA01503', 'JDOE0001', 'JPATTER1', 'R', 'DL', 46250.00, 1995.00, 48245.00, 799.00, 1399.10, 482.45, 7.20, 50.00, 50982.75, 12000.00, 38982.75, 2775.00, 1200.00, 3975.00, '2026-02-10', '2026-02-14'),
('DL01000104', 'DLR01', 4, '1FTFW1E53PFA01504', 'TSMITH01', 'JPATTER1', 'R', 'DL', 46250.00, 1995.00, 48245.00, 799.00, 1399.10, 482.45, 7.20, 50.00, 50982.75, 9500.00, 41482.75, 2812.50, 1425.00, 4237.50, '2026-03-18', '2026-03-22'),
('DL01000105', 'DLR01', 5, '1FMCU9J93NUA01501', 'JDOE0001', 'JPATTER1', 'R', 'DL', 36400.00, 1495.00, 37895.00, 799.00, 1098.95, 378.95, 7.20, 50.00, 40229.05, 6500.00, 33729.05, 1842.00, 925.00, 2767.00, '2026-01-04', '2026-01-08'),
('DL01000106', 'DLR01', 1, '1FMCU9J93NUA01502', 'TSMITH01', 'JPATTER1', 'R', 'DL', 36400.00, 1495.00, 37895.00, 799.00, 1098.95, 378.95, 7.20, 50.00, 40229.05, 5000.00, 35229.05, 1958.00, 1075.00, 3033.00, '2026-03-22', '2026-03-26'),
('DL01000107', 'DLR01', 6, '1FA6P8CF7N5A01501', 'JDOE0001', 'JPATTER1', 'R', 'DL', 44090.00, 1595.00, 45685.00, 799.00, 1324.87, 456.85, 7.20, 50.00, 48322.92, 15000.00, 33322.92, 2823.00, 1650.00, 4473.00, '2026-02-14', '2026-02-18'),
('DL01000108', 'DLR01', 2, '1FM5K8GC7PGA01501', 'TSMITH01', 'JPATTER1', 'R', 'DL', 52960.00, 1895.00, 54855.00, 799.00, 1590.80, 548.55, 7.20, 50.00, 57850.55, 12500.00, 45350.55, 3177.60, 1375.00, 4552.60, '2026-03-30', '2026-04-03'),
('DL01000109', 'DLR01', 3, '1FM5K8GC7PGA01502', 'JDOE0001', 'JPATTER1', 'R', 'DL', 52960.00, 1995.00, 54955.00, 799.00, 1593.70, 549.55, 7.20, 50.00, 57954.45, 11000.00, 46954.45, 3177.60, 1500.00, 4677.60, '2026-04-13', '2026-04-15'),
('DL01000110', 'DLR01', 4, '1FTFW1E53PFA01505', 'TSMITH01', 'JPATTER1', 'R', 'WS', 46250.00, 1995.00, 48245.00, 799.00, 0.00, 0.00, 7.20, 50.00, 49101.20, 0.00, 0.00, 0.00, 0.00, 0.00, '2026-04-15', NULL);

-- ── Deals — DLR06 Plainfield Ford (Volume leader #2 — 12 new deals) ─
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL06000001', 'DLR06', 7,  '1FMCU9J93NUA06101', 'JSMITH06', 'ARUSSO06', 'R', 'DL', 36400.00, 1495.00, 37895.00, 499.00, 2513.96, 0.00, 60.00, 46.00, 41013.96, 6000.00, 35013.96, 1820.00, 950.00, 2770.00, '2026-01-09', '2026-01-13'),
('DL06000002', 'DLR06', 8,  '1FA6P8CF7N5A06202', 'TBROWN06', 'ARUSSO06', 'R', 'DL', 44090.00, 1595.00, 45685.00, 499.00, 3029.91, 0.00, 60.00, 46.00, 49319.91, 10000.00, 39319.91, 2645.40, 1200.00, 3845.40, '2026-03-16', '2026-03-20'),
('DL06000003', 'DLR06', 9,  '1FTFW1E53NFA06001', 'JSMITH06', 'ARUSSO06', 'R', 'DL', 44970.00, 1895.00, 46865.00, 499.00, 3107.95, 0.00, 60.00, 46.00, 50577.95, 9500.00, 41077.95, 2473.35, 1100.00, 3573.35, '2026-01-28', '2026-02-02'),
('DL06000004', 'DLR06', 10, '1FTFW1E53NFA06002', 'TBROWN06', 'ARUSSO06', 'R', 'DL', 44970.00, 1895.00, 46865.00, 499.00, 3107.95, 0.00, 60.00, 46.00, 50577.95, 12000.00, 38577.95, 2698.00, 1325.00, 4023.00, '2026-02-20', '2026-02-24'),
('DL06000005', 'DLR06', 11, '1FTFW1E53PFA06003', 'JSMITH06', 'ARUSSO06', 'R', 'DL', 46250.00, 1995.00, 48245.00, 499.00, 3198.64, 0.00, 60.00, 46.00, 52048.64, 11500.00, 40548.64, 2775.00, 1150.00, 3925.00, '2026-03-12', '2026-03-16'),
('DL06000006', 'DLR06', 12, '1FTFW1E53PFA06004', 'TBROWN06', 'ARUSSO06', 'R', 'DL', 46250.00, 1995.00, 48245.00, 499.00, 3198.64, 0.00, 60.00, 46.00, 52048.64, 13000.00, 39048.64, 2775.00, 1400.00, 4175.00, '2026-04-05', '2026-04-09'),
('DL06000007', 'DLR06', 7,  '1FTFW1E53PFA06005', 'JSMITH06', 'ARUSSO06', 'R', 'WS', 46250.00, 1995.00, 48245.00, 499.00, 0.00, 0.00, 60.00, 46.00, 48850.00, 0.00, 0.00, 0.00, 0.00, 0.00, '2026-04-14', NULL),
('DL06000008', 'DLR06', 8,  '1FM5K8GC7PGA06301', 'TBROWN06', 'ARUSSO06', 'R', 'DL', 52960.00, 1895.00, 54855.00, 499.00, 3637.09, 0.00, 60.00, 46.00, 59097.09, 14000.00, 45097.09, 3177.60, 1275.00, 4452.60, '2026-03-08', '2026-03-12'),
('DL06000009', 'DLR06', 9,  '1FM5K8GC7PGA06302', 'JSMITH06', 'ARUSSO06', 'R', 'AP', 52960.00, 1995.00, 54955.00, 499.00, 3643.72, 0.00, 60.00, 46.00, 59203.72, 12000.00, 47203.72, 0.00, 0.00, 0.00, '2026-04-10', NULL),
('DL06000010', 'DLR06', 10, '1FMCU9J93NUA06103', 'TBROWN06', 'ARUSSO06', 'R', 'DL', 36400.00, 1495.00, 37895.00, 499.00, 2513.96, 0.00, 60.00, 46.00, 41013.96, 7500.00, 33513.96, 1820.00, 985.00, 2805.00, '2026-03-30', '2026-04-02'),
('DL06000011', 'DLR06', 11, '1FMCU9J93NUA06102', 'JSMITH06', 'ARUSSO06', 'R', 'DL', 36400.00, 1495.00, 37895.00, 499.00, 2513.96, 0.00, 60.00, 46.00, 41013.96, 5500.00, 35513.96, 2002.00, 1050.00, 3052.00, '2025-11-18', '2025-11-22'),
('DL06000012', 'DLR06', 12, '1FA6P8CF7N5A06201', 'TBROWN06', 'ARUSSO06', 'R', 'DL', 44090.00, 1595.00, 45685.00, 499.00, 3029.91, 0.00, 60.00, 46.00, 49319.91, 18000.00, 31319.91, 2645.40, 1125.00, 3770.40, '2026-02-05', '2026-02-09');

-- ── Deals — DLR02 Northside Toyota (Luxury #1 — 4 new deals) ────────
-- Higher-trim units, front gross $4,000-$6,000, back gross $1,500-$2,500
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL02000101', 'DLR02', 8,  '5TDBKRFH5NS401501', 'DJONES02', 'MSANTOS1', 'R', 'DL', 44290.00, 1495.00, 45785.00, 199.00, 3216.75, 0.00, 15.00, 21.35, 49237.10, 8000.00, 41237.10, 3986.10, 1850.00, 5836.10, '2025-12-22', '2025-12-27'),
('DL02000102', 'DLR02', 9,  '5TDBKRFH5NS401502', 'APARK002', 'MSANTOS1', 'R', 'DL', 44290.00, 1495.00, 45785.00, 199.00, 3216.75, 0.00, 15.00, 21.35, 49237.10, 12000.00, 37237.10, 4163.25, 2100.00, 6263.25, '2026-03-13', '2026-03-17'),
('DL02000103', 'DLR02', 10, '5TDBKRFH5NS401503', 'DJONES02', 'MSANTOS1', 'L', 'DL', 44290.00, 1495.00, 45785.00, 199.00, 3216.75, 0.00, 15.00, 21.35, 49237.10, 5000.00, 44237.10, 4428.50, 2450.00, 6878.50, '2026-04-12', '2026-04-14'),
('DL02000104', 'DLR02', 11, '4T1BF1FK5PU201501', 'APARK002', 'MSANTOS1', 'R', 'DL', 30250.00, 1145.00, 31395.00, 199.00, 2205.57, 0.00, 15.00, 21.35, 33835.92, 7000.00, 26835.92, 2625.00, 1400.00, 4025.00, '2026-02-10', '2026-02-14');

-- ── Deals — DLR07 Charlotte BMW (Luxury #2 — 5 new deals) ───────────
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL07000001', 'DLR07', 25, 'WBA5R1C50NFJ07001', 'DGOLD07', 'VPRICE07', 'L', 'DL', 46400.00, 995.00, 47395.00, 799.00, 2251.26, 947.90, 14.00, 52.00, 51459.16, 5000.00, 46459.16, 4872.00, 2650.00, 7522.00, '2025-12-20', '2025-12-23'),
('DL07000002', 'DLR07', 26, 'WBA5R1C50NFJ07002', 'CGREY07', 'VPRICE07', 'R', 'DL', 46400.00, 995.00, 47395.00, 799.00, 2251.26, 947.90, 14.00, 52.00, 51459.16, 15000.00, 36459.16, 5104.00, 2850.00, 7954.00, '2026-02-22', '2026-02-26'),
('DL07000003', 'DLR07', 27, '5UXCR6C05NLL07001', 'DGOLD07', 'VPRICE07', 'R', 'DL', 67900.00, 995.00, 68895.00, 799.00, 3272.51, 1377.90, 14.00, 52.00, 74410.41, 22000.00, 52410.41, 7469.00, 3750.00, 11219.00, '2026-01-13', '2026-01-17'),
('DL07000004', 'DLR07', 28, '5UXCR6C05NLL07002', 'CGREY07', 'VPRICE07', 'L', 'DL', 67900.00, 995.00, 68895.00, 799.00, 3272.51, 1377.90, 14.00, 52.00, 74410.41, 10000.00, 64410.41, 8148.00, 4200.00, 12348.00, '2026-03-05', '2026-03-09'),
('DL07000005', 'DLR07', 29, 'WBY73AW05PFM07001', 'DGOLD07', 'VPRICE07', 'L', 'DL', 87100.00, 995.00, 88095.00, 799.00, 4184.51, 1761.90, 14.00, 52.00, 94906.41, 15000.00, 79906.41, 11323.00, 5100.00, 16423.00, '2026-02-28', '2026-03-04');

-- ── Deals — DLR03 Valley Honda (Struggling #1 — 3 new deals) ────────
-- Low front gross, no back gross (poor F&I attach), some old dates
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL03000101', 'DLR03', 13, '19XFC1F38NE501501', 'KLEE0003', 'RNGUYEN3', 'R', 'DL', 28950.00, 1095.00, 30045.00, 599.00, 1682.52, 210.32, 4.00, 32.00, 32572.84, 4500.00, 28072.84, 868.50, 325.00, 1193.50, '2025-08-10', '2025-08-14'),
('DL03000102', 'DLR03', 14, '7FARW2H93NE601501', 'LWONG003', 'RNGUYEN3', 'R', 'DL', 38600.00, 1295.00, 39895.00, 599.00, 2234.12, 279.27, 4.00, 32.00, 43043.39, 6000.00, 37043.39, 1544.00, 485.00, 2029.00, '2025-10-25', '2025-10-30'),
('DL03000103', 'DLR03', 15, '1HGCV3F16PA701501', 'KLEE0003', 'RNGUYEN3', 'R', 'DL', 34850.00, 1195.00, 36045.00, 599.00, 2018.52, 252.32, 4.00, 32.00, 38950.84, 5500.00, 33450.84, 1045.50, 425.00, 1470.50, '2026-03-18', '2026-03-22');

-- ── Deals — DLR08 Riverside Honda (Struggling #2 — 2 new deals) ─────
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL08000001', 'DLR08', 13, '19XFC1F38NE508004', 'KSANT08', 'DFERNA08', 'R', 'DL', 28950.00, 1095.00, 30045.00,  85.00, 2178.26, 300.45, 25.00, 88.00, 32721.71, 3500.00, 29221.71, 723.75, 285.00, 1008.75, '2025-08-15', '2025-08-20'),
('DL08000002', 'DLR08', 14, '7FARW2H93NE608004', 'TLOW08',  'DFERNA08', 'R', 'WS', 38600.00, 1295.00, 39895.00,  85.00, 0.00, 0.00, 25.00, 88.00, 40093.00, 0.00, 0.00, 0.00, 0.00, 0.00, '2026-04-12', NULL);

-- ── Deals — DLR04 Peachtree Chevrolet (Warranty hotspot #1 — 6 deals) ─
-- Normal volume, mid gross
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, city_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL04000101', 'DLR04', 19, '1GCUYEED5NZ901501', 'MBROWN04', 'WCLARK04', 'R', 'DL', 47300.00, 1895.00, 49195.00, 699.00, 1967.80, 1475.85, 737.93, 18.00, 20.00, 54113.58, 12000.00, 42113.58, 2365.00, 1250.00, 3615.00, '2025-11-20', '2025-11-25'),
('DL04000102', 'DLR04', 20, '1GCUYEED5NZ901502', 'RGREEN04', 'WCLARK04', 'R', 'DL', 47300.00, 1895.00, 49195.00, 699.00, 1967.80, 1475.85, 737.93, 18.00, 20.00, 54113.58, 14000.00, 40113.58, 2838.00, 1375.00, 4213.00, '2026-01-10', '2026-01-14'),
('DL04000103', 'DLR04', 21, '3GNAXKEV0PS101501', 'MBROWN04', 'WCLARK04', 'R', 'DL', 35900.00, 1395.00, 37295.00, 699.00, 1491.80, 1118.85, 559.43, 18.00, 20.00, 41202.08, 8000.00, 33202.08, 1795.00, 1050.00, 2845.00, '2026-02-18', '2026-02-22'),
('DL04000104', 'DLR04', 22, '3GNAXKEV0PS101502', 'RGREEN04', 'WCLARK04', 'R', 'DL', 35900.00, 1395.00, 37295.00, 699.00, 1491.80, 1118.85, 559.43, 18.00, 20.00, 41202.08, 9500.00, 31702.08, 2154.00, 1225.00, 3379.00, '2026-03-26', '2026-03-30'),
('DL04000105', 'DLR04', 23, '1G1ZD5STXNF201501', 'MBROWN04', 'WCLARK04', 'R', 'DL', 28590.00, 1195.00, 29785.00, 699.00, 1191.40, 893.55, 446.78, 18.00, 20.00, 33053.73, 5000.00, 28053.73, 1429.50, 850.00, 2279.50, '2026-04-03', '2026-04-07'),
('DL04000106', 'DLR04', 24, '1G1ZD5STXNF201502', 'RGREEN04', 'WCLARK04', 'R', 'WS', 28590.00, 1195.00, 29785.00, 699.00, 0.00, 0.00, 0.00, 18.00, 20.00, 30522.00, 0.00, 0.00, 0.00, 0.00, 0.00, '2026-04-15', NULL);

-- ── Deals — DLR09 Dallas Chevrolet (Warranty hotspot #2 — 7 deals) ──
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL09000001', 'DLR09', 15, '1GCUYEED5NZ909001', 'MJOHN09',  'CBENNT09', 'R', 'DL', 47300.00, 1895.00, 49195.00, 150.00, 3074.69, 491.95, 28.00, 51.75, 52991.39, 12000.00, 40991.39, 2365.00, 1300.00, 3665.00, '2025-12-15', '2025-12-20'),
('DL09000002', 'DLR09', 16, '1GCUYEED5NZ909002', 'BFOSTER9', 'CBENNT09', 'R', 'DL', 47300.00, 1895.00, 49195.00, 150.00, 3074.69, 491.95, 28.00, 51.75, 52991.39, 14000.00, 38991.39, 2838.00, 1425.00, 4263.00, '2026-01-22', '2026-01-26'),
('DL09000003', 'DLR09', 17, '1GCUYEED5NZ909003', 'MJOHN09',  'CBENNT09', 'R', 'DL', 47300.00, 1895.00, 49195.00, 150.00, 3074.69, 491.95, 28.00, 51.75, 52991.39, 11000.00, 41991.39, 2365.00, 1175.00, 3540.00, '2026-02-26', '2026-03-02'),
('DL09000004', 'DLR09', 18, '3GNAXKEV0PS109001', 'BFOSTER9', 'CBENNT09', 'R', 'DL', 35900.00, 1395.00, 37295.00, 150.00, 2330.94, 372.95, 28.00, 51.75, 40228.64, 8000.00, 32228.64, 1795.00, 1100.00, 2895.00, '2026-01-12', '2026-01-16'),
('DL09000005', 'DLR09', 19, '3GNAXKEV0PS109002', 'MJOHN09',  'CBENNT09', 'R', 'DL', 35900.00, 1395.00, 37295.00, 150.00, 2330.94, 372.95, 28.00, 51.75, 40228.64, 10000.00, 30228.64, 2154.00, 1225.00, 3379.00, '2026-02-18', '2026-02-22'),
('DL09000006', 'DLR09', 20, '3GNAXKEV0PS109003', 'BFOSTER9', 'CBENNT09', 'R', 'DL', 35900.00, 1395.00, 37295.00, 150.00, 2330.94, 372.95, 28.00, 51.75, 40228.64, 9000.00, 31228.64, 1795.00, 1050.00, 2845.00, '2026-03-28', '2026-04-01'),
('DL09000007', 'DLR09', 21, '1G1ZD5STXNF209001', 'MJOHN09',  'CBENNT09', 'R', 'WS', 28590.00, 1195.00, 29785.00, 150.00, 0.00, 0.00, 28.00, 51.75, 30014.75, 0.00, 0.00, 0.00, 0.00, 0.00, '2026-04-14', NULL);

-- ── Deals — DLR05 Prestige BMW (F&I powerhouse #1 — 7 deals) ────────
-- Back gross exceeds or matches front gross — hallmark of F&I powerhouse
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL05000101', 'DLR05', 25, 'WBA5R1C50NFJ01501', 'PCHEN005', 'EHART005', 'L', 'DL', 46400.00,  995.00, 47395.00, 599.00, 3009.58, 25.00, 120.00, 51148.58, 8000.00, 43148.58, 3248.00, 3850.00, 7098.00, '2025-12-18', '2025-12-22'),
('DL05000102', 'DLR05', 26, 'WBA5R1C50NFJ01502', 'SLEE0005', 'EHART005', 'L', 'DL', 46400.00,  995.00, 47395.00, 599.00, 3009.58, 25.00, 120.00, 51148.58, 9500.00, 41648.58, 3480.00, 4125.00, 7605.00, '2026-03-02', '2026-03-06'),
('DL05000103', 'DLR05', 27, '5UXCR6C05NLL01501', 'PCHEN005', 'EHART005', 'L', 'DL', 67900.00,  995.00, 68895.00, 599.00, 4374.83, 25.00, 120.00, 74013.83, 15000.00, 59013.83, 4753.00, 5125.00, 9878.00, '2026-01-22', '2026-01-26'),
('DL05000104', 'DLR05', 28, '5UXCR6C05NLL01502', 'SLEE0005', 'EHART005', 'L', 'DL', 67900.00,  995.00, 68895.00, 599.00, 4374.83, 25.00, 120.00, 74013.83, 18000.00, 56013.83, 5092.50, 5450.00, 10542.50, '2026-03-18', '2026-03-22'),
('DL05000105', 'DLR05', 29, 'WBY73AW05PFM01501', 'PCHEN005', 'EHART005', 'L', 'DL', 87100.00,  995.00, 88095.00, 599.00, 5594.03, 25.00, 120.00, 94433.03, 20000.00, 74433.03, 6532.50, 6800.00, 13332.50, '2026-04-01', '2026-04-05'),
('DL05000106', 'DLR05', 30, 'WBY73AW05PFM01502', 'SLEE0005', 'EHART005', 'L', 'DL', 87100.00,  995.00, 88095.00, 599.00, 5594.03, 25.00, 120.00, 94433.03, 22000.00, 72433.03, 7840.00, 7250.00, 15090.00, '2026-04-14', '2026-04-16');

-- ── Deals — DLR10 Boise Toyota (F&I powerhouse #2 — 8 deals) ────────
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, city_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL10000001', 'DLR10', 22, '4T1BF1FK5NU101001', 'SMART10',  'RLARSE10', 'R', 'DL', 29495.00, 1095.00, 30590.00, 399.00, 1835.40, 0.00, 305.90, 14.00, 48.00, 33192.30, 5000.00, 28192.30, 1769.70, 2450.00, 4219.70, '2026-01-08', '2026-01-12'),
('DL10000002', 'DLR10', 23, '4T1BF1FK5PU201001', 'EYOUNG10', 'RLARSE10', 'R', 'DL', 30250.00, 1145.00, 31395.00, 399.00, 1883.70, 0.00, 313.95, 14.00, 48.00, 34067.65, 6500.00, 27567.65, 2118.75, 2625.00, 4743.75, '2026-02-20', '2026-02-24'),
('DL10000003', 'DLR10', 24, '4T1BF1FK5PU201002', 'SMART10',  'RLARSE10', 'R', 'DL', 30250.00, 1145.00, 31395.00, 399.00, 1883.70, 0.00, 313.95, 14.00, 48.00, 34067.65, 8000.00, 26067.65, 2268.75, 2775.00, 5043.75, '2026-03-30', '2026-04-03'),
('DL10000004', 'DLR10', 25, '2T3WFREV5NW201001', 'EYOUNG10', 'RLARSE10', 'R', 'DL', 37535.00, 1335.00, 38870.00, 399.00, 2332.20, 0.00, 388.70, 14.00, 48.00, 42051.90, 8000.00, 34051.90, 2252.10, 3150.00, 5402.10, '2026-01-18', '2026-01-22'),
('DL10000005', 'DLR10', 26, '2T3WFREV5NW201002', 'SMART10',  'RLARSE10', 'R', 'DL', 37535.00, 1335.00, 38870.00, 399.00, 2332.20, 0.00, 388.70, 14.00, 48.00, 42051.90, 9500.00, 32551.90, 2627.45, 3325.00, 5952.45, '2026-02-25', '2026-03-01'),
('DL10000006', 'DLR10', 27, '3TMCZ5AN5NM301001', 'EYOUNG10', 'RLARSE10', 'R', 'DL', 37250.00, 1335.00, 38585.00, 399.00, 2315.10, 0.00, 385.85, 14.00, 48.00, 41746.95, 7000.00, 34746.95, 2235.00, 3075.00, 5310.00, '2026-02-12', '2026-02-16'),
('DL10000007', 'DLR10', 28, '3TMCZ5AN5NM301002', 'SMART10',  'RLARSE10', 'R', 'DL', 37250.00, 1335.00, 38585.00, 399.00, 2315.10, 0.00, 385.85, 14.00, 48.00, 41746.95, 8500.00, 33246.95, 2607.50, 3250.00, 5857.50, '2026-03-22', '2026-03-26'),
('DL10000008', 'DLR10', 29, '5TDBKRFH5NS401001', 'EYOUNG10', 'RLARSE10', 'R', 'DL', 44290.00, 1495.00, 45785.00, 399.00, 2747.10, 0.00, 457.85, 14.00, 48.00, 49450.95, 10000.00, 39450.95, 3100.30, 3550.00, 6650.30, '2026-01-23', '2026-01-27');

-- ── Deals — DLR11 Madison Ford (Baseline #1 — 5 deals) ──────────────
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL11000001', 'DLR11', 30, '1FTFW1E53NFA11002', 'JWOOD11',  'GANDER11', 'R', 'DL', 44970.00, 1895.00, 46865.00, 399.00, 2343.25, 257.76, 69.50, 75.00, 50009.51, 10000.00, 40009.51, 2473.35, 1175.00, 3648.35, '2026-02-22', '2026-02-26'),
('DL11000002', 'DLR11', 19, '1FMCU9J93NUA11101', 'HKNIGH1',  'GANDER11', 'R', 'DL', 36400.00, 1495.00, 37895.00, 399.00, 1894.75, 208.42, 69.50, 75.00, 40541.67, 6000.00, 34541.67, 1820.00, 1050.00, 2870.00, '2025-12-15', '2025-12-20'),
('DL11000003', 'DLR11', 20, '1FMCU9J93NUA11102', 'JWOOD11',  'GANDER11', 'R', 'DL', 36400.00, 1495.00, 37895.00, 399.00, 1894.75, 208.42, 69.50, 75.00, 40541.67, 7500.00, 33041.67, 2002.00, 1125.00, 3127.00, '2026-03-30', '2026-04-03'),
('DL11000004', 'DLR11', 21, '1FA6P8CF7N5A11201', 'HKNIGH1',  'GANDER11', 'R', 'DL', 44090.00, 1595.00, 45685.00, 399.00, 2284.25, 251.27, 69.50, 75.00, 48764.02, 12000.00, 36764.02, 2645.40, 1300.00, 3945.40, '2026-03-15', '2026-03-19'),
('DL11000005', 'DLR11', 22, '1FM5K8GC7PGA11301', 'JWOOD11',  'GANDER11', 'R', 'DL', 52960.00, 1895.00, 54855.00, 399.00, 2742.75, 301.70, 69.50, 75.00, 58442.95, 15000.00, 43442.95, 3177.60, 1425.00, 4602.60, '2026-02-28', '2026-03-04');

-- ── Deals — DLR12 Albany Honda (Baseline #2 — 4 deals) ──────────────
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, city_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
('DL12000001', 'DLR12', 23, '7FARW2H93NE612001', 'GLOPE12',  'MRODRI12', 'R', 'DL', 38600.00, 1295.00, 39895.00, 175.00, 1595.80, 1695.54, 179.53, 50.00, 26.00, 43616.87, 7000.00, 36616.87, 1930.00, 1175.00, 3105.00, '2026-02-02', '2026-02-06'),
('DL12000002', 'DLR12', 24, '19XFC1F38NE512001', 'OWARD12',  'MRODRI12', 'R', 'DL', 28950.00, 1095.00, 30045.00, 175.00, 1201.80, 1276.91, 135.20, 50.00, 26.00, 32910.91, 5000.00, 27910.91, 1447.50, 1025.00, 2472.50, '2025-12-28', '2026-01-02'),
('DL12000003', 'DLR12', 25, '1HGCV3F16PA712001', 'GLOPE12',  'MRODRI12', 'R', 'DL', 34850.00, 1195.00, 36045.00, 175.00, 1441.80, 1531.91, 162.20, 50.00, 26.00, 39431.91, 8000.00, 31431.91, 1742.50, 1100.00, 2842.50, '2026-03-10', '2026-03-14'),
('DL12000004', 'DLR12', 26, '5FNYF6H95NB812001', 'OWARD12',  'MRODRI12', 'R', 'DL', 46050.00, 1495.00, 47545.00, 175.00, 1901.80, 2020.66, 213.95, 50.00, 26.00, 51932.41, 12000.00, 39932.41, 2302.50, 1350.00, 3652.50, '2026-04-06', '2026-04-10');

-- ── Sync vehicle status: AV → SD for all delivered deals ────────────
-- Keeps "inventory available" queries accurate. AI agent asking "what's on
-- the lot?" would otherwise count sold vehicles as available.
UPDATE vehicle
SET vehicle_status = 'SD',
    updated_ts = CURRENT_TIMESTAMP
WHERE vehicle_status = 'AV'
  AND vin IN (SELECT vin FROM sales_deal WHERE deal_status = 'DL');
