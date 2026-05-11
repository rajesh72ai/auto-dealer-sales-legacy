-- ============================================================
-- V71: Recent demo data for the 2026-05-11 customer demo
--
-- V60-V66 seed data tops out around 2026-04-15. This migration
-- fills 2026-04-27 → 2026-05-11 so prompts like "deals this week"
-- and "stale finance apps" return meaningful results.
--
-- Conventions reused exactly from V60/V61:
--   VIN          : <12-char-prefix><dealer2><seq3> = 17 chars
--                  char 10 encodes model year (N=2025, P=2026)
--                  e.g. 1FTFW1E53PFA01571 = 2026 F-150 / DLR01 / seq 571
--   stock_number : <MakeLetter><DealerNum>-<modelDigit><seq3>
--                  DLR01: F150=15xx, ESC=16xx, Mustang=17xx, Explorer=18xx
--                  DLR07: X5=16xx
--   Deal #       : DL<dealer2>0<seq5>  → DL01000200-205, DL06000200, DL07000200
--   Shipment ID  : SH<YY>-<seq7>       → SH26-0000200-202
--   Claim #      : CL<seq6>            → CL710001-003
--   Finance ID   : FIN<seq8>           → FIN71000001-005
--
-- All sequence ranges chosen well above existing V60-V66 + below
-- SequenceGenerator floor (1000) so framework writes won't collide.
--
-- Idempotent (ON CONFLICT DO NOTHING on PKs).
-- ============================================================

-- ── 1. New vehicles (3 fresh AV at DLR01, 1 BMW DLR07, 4 sold-back, 2 aged DLR01) ──
INSERT INTO vehicle (vin, model_year, make_code, model_code, exterior_color, interior_color, production_date, ship_date, receive_date, vehicle_status, dealer_code, lot_location, stock_number, days_in_stock, pdi_complete, pdi_date, odometer) VALUES
-- DLR01 fresh stock arrived in past 2 weeks (back the SH26-0000200 shipment)
('1FTFW1E53PFA01571', 2026, 'FRD', 'F150XL', 'BLU', 'BLK', '2026-03-20', '2026-04-15', '2026-04-28', 'AV', 'DLR01', 'SHOW01', 'F01-1571', 13, 'Y', '2026-04-29', 4),
('1FTFW1E53PFA01572', 2026, 'FRD', 'F150XL', 'WHT', 'GRY', '2026-03-25', '2026-04-18', '2026-05-02', 'AV', 'DLR01', 'FRNT01', 'F01-1572', 9,  'Y', '2026-05-03', 6),
('1FMCU9J93NUA01573', 2025, 'FRD', 'ESCSEL', 'RED', 'BLK', '2026-03-28', '2026-04-22', '2026-05-05', 'AV', 'DLR01', 'SHOW01', 'F01-1671', 6,  'Y', '2026-05-06', 3),
-- DLR01 sold (back recent deals)
('1FTFW1E53PFA01573', 2026, 'FRD', 'F150XL', 'BLK', 'BLK', '2026-02-15', '2026-03-12', '2026-03-25', 'SD', 'DLR01', NULL, 'F01-1573', 47, 'Y', '2026-03-26', 8),
('1FA6P8CF7N5A01571', 2025, 'FRD', 'MUSTGT', 'RED', 'BLK', '2026-02-25', '2026-03-20', '2026-04-02', 'SD', 'DLR01', NULL, 'F01-1771', 39, 'Y', '2026-04-03', 5),
('1FM5K8GC7PGA01571', 2026, 'FRD', 'EXPLLT', 'WHT', 'TAN', '2026-03-05', '2026-03-28', '2026-04-12', 'SD', 'DLR01', NULL, 'F01-1871', 29, 'Y', '2026-04-13', 4),
-- DLR01 AGED stock (200+ days) — for the inventory-aging prompt at DLR01
('1FTFW1E53NFA01571', 2025, 'FRD', 'F150XL', 'GRN', 'GRY', '2025-09-15', '2025-10-08', '2025-10-20', 'AV', 'DLR01', 'BACK01', 'F01-1574', 203, 'Y', '2025-10-21', 38),
('1FMCU9J93NUA01572', 2025, 'FRD', 'ESCSEL', 'YEL', 'TAN', '2025-08-25', '2025-09-18', '2025-10-01', 'AV', 'DLR01', 'BACK01', 'F01-1672', 222, 'Y', '2025-10-02', 42),
-- DLR06 sold
('1FTFW1E53PFA06571', 2026, 'FRD', 'F150XL', 'SLV', 'BLK', '2026-03-10', '2026-04-05', '2026-04-18', 'SD', 'DLR06', NULL, 'F06-0171', 23, 'Y', '2026-04-19', 6),
-- DLR07 BMW sold
('5UXCR6C05NLL07571', 2025, 'BMW', 'X5XD40', 'BLK', 'TAN', '2026-02-28', '2026-03-25', '2026-04-08', 'SD', 'DLR07', NULL, 'B07-1671', 33, 'Y', '2026-04-09', 5)
ON CONFLICT (vin) DO NOTHING;

-- ── 2. New deals (8) — recent dealmaking, mix of DL/AP/CA/WS for prompt diversity ──
-- Customer IDs verified live (API peek 2026-05-11): DLR01 has Henderson(1), Mitchell(2),
-- Garcia(3), Reyes(6), Garza(31), Bennett(32). DLR06 V61 used 7-12. DLR07 used 25-29.
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id, deal_type, deal_status, vehicle_price, destination_fee, subtotal, doc_fee, state_tax, county_tax, title_fee, reg_fee, total_price, down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date, delivery_date) VALUES
-- DLR01 — 6 recent deals, mixed statuses for analysis prompts + write demo enablement
('DL01000200', 'DLR01', 1,  '1FTFW1E53PFA01573', 'TSMITH01', 'JPATTER1', 'R', 'DL', 46250.00, 1995.00, 48245.00, 799.00, 1399.10, 482.45, 7.20, 50.00, 50982.75, 10000.00, 40982.75, 2775.00, 1350.00, 4125.00, '2026-04-28', '2026-05-02'),
('DL01000201', 'DLR01', 3,  '1FA6P8CF7N5A01571', 'JDOE0001', 'JPATTER1', 'R', 'DL', 44090.00, 1595.00, 45685.00, 799.00, 1324.87, 456.85, 7.20, 50.00, 48322.92, 14000.00, 34322.92, 2823.00, 1525.00, 4348.00, '2026-05-03', '2026-05-07'),
('DL01000202', 'DLR01', 2,  '1FM5K8GC7PGA01571', 'TSMITH01', 'JPATTER1', 'R', 'DL', 52960.00, 1995.00, 54955.00, 799.00, 1593.70, 549.55, 7.20, 50.00, 57954.45, 12000.00, 45954.45, 3177.60, 1675.00, 4852.60, '2026-05-08', '2026-05-10'),
-- Today's deal in WS (working sheet) — for W3 add_trade_in / W4 submit_finance demos
('DL01000203', 'DLR01', 31, '1FTFW1E53PFA01571', 'TSMITH01', 'JPATTER1', 'R', 'WS', 46250.00, 1995.00, 48245.00, 799.00, 0.00,    0.00,   7.20, 50.00, 49101.20,     0.00,     0.00,    0.00,    0.00,    0.00, '2026-05-11', NULL),
-- Yesterday's deal in CA (credit app submitted) — for W5 approve_deal demo
('DL01000204', 'DLR01', 32, '1FTFW1E53PFA01572', 'JDOE0001', 'JPATTER1', 'R', 'CA', 46250.00, 1995.00, 48245.00, 799.00, 1399.10, 482.45, 7.20, 50.00, 50982.75,  8000.00, 42982.75,    0.00,    0.00,    0.00, '2026-05-10', NULL),
-- Day-old deal in AP (approved, in finance) — alternate approve target
('DL01000205', 'DLR01', 6,  '1FMCU9J93NUA01573', 'TSMITH01', 'JPATTER1', 'R', 'AP', 36400.00, 1495.00, 37895.00, 799.00, 1098.95, 378.95, 7.20, 50.00, 40229.05,  7000.00, 33229.05,    0.00,    0.00,    0.00, '2026-05-09', NULL),
-- DLR06 — 1 recent
('DL06000200', 'DLR06', 7,  '1FTFW1E53PFA06571', 'JSMITH06', 'ARUSSO06', 'R', 'DL', 46250.00, 1995.00, 48245.00, 499.00, 3198.64, 0.00,   60.00, 46.00, 52048.64, 12000.00, 40048.64, 2775.00, 1275.00, 4050.00, '2026-04-30', '2026-05-04'),
-- DLR07 — 1 recent BMW
('DL07000200', 'DLR07', 27, '5UXCR6C05NLL07571', 'DGOLD07',  'VPRICE07', 'R', 'DL', 67900.00, 995.00,  68895.00, 799.00, 3272.51, 1377.90, 14.00, 52.00, 74410.41, 25000.00, 49410.41, 7469.00, 3850.00,11319.00, '2026-05-05', '2026-05-09')
ON CONFLICT (deal_number) DO NOTHING;

-- ── 3. New leads (12) — recent pipeline activity ───────────────────
INSERT INTO customer_lead (customer_id, dealer_code, lead_source, interest_model, interest_year, lead_status, assigned_sales, follow_up_date, last_contact_dt, contact_count, notes) VALUES
-- DLR01 — 6 fresh, mix of NW/CT/QF/PR for funnel storytelling
(1,  'DLR01', 'WLK', 'F150XL', 2026, 'NW', 'TSMITH01', '2026-05-13', '2026-05-11', 1, 'Walked in this morning, interested in 2026 F-150.'),
(2,  'DLR01', 'WEB', 'EXPLLT', 2026, 'CT', 'JDOE0001', '2026-05-14', '2026-05-10', 2, 'Following up on web inquiry from yesterday.'),
(3,  'DLR01', 'REF', 'MUSTGT', 2026, 'QF', 'TSMITH01', '2026-05-15', '2026-05-09', 3, 'Referred by Henderson; pre-approved, test drive Saturday.'),
(6,  'DLR01', 'WEB', 'ESCSEL', 2026, 'PR', 'JDOE0001', '2026-05-12', '2026-05-08', 2, 'Negotiating Escape SEL hybrid; trade-in evaluation pending.'),
(31, 'DLR01', 'ADV', 'F150XL', 2026, 'CT', 'TSMITH01', '2026-05-13', '2026-05-06', 1, 'Responded to billboard ad, requesting quote.'),
(32, 'DLR01', 'RPT', 'EXPLLT', 2026, 'NW', 'JDOE0001', '2026-05-13', '2026-05-04', 1, 'Repeat customer asking about 2026 Explorer Limited.'),
-- DLR06 — 3 leads
(7,  'DLR06', 'WEB', 'F150XL', 2026, 'CT', 'JSMITH06', '2026-05-14', '2026-05-09', 2, 'Online inquiry, follow-up needed.'),
(8,  'DLR06', 'WLK', 'EXPLLT', 2026, 'QF', 'TBROWN06', '2026-05-12', '2026-05-07', 3, 'Walked in last week, qualified, scheduling appointment.'),
(9,  'DLR06', 'REF', 'MUSTGT', 2026, 'NW', 'JSMITH06', '2026-05-15', '2026-05-11', 1, 'Brand new inquiry from referral.'),
-- DLR04 — 2 leads
(19, 'DLR04', 'WEB', 'EQNOLT', 2026, 'PR', 'MBROWN04', '2026-05-13', '2026-05-08', 3, 'EV-curious customer; running numbers on Equinox EV.'),
(20, 'DLR04', 'REF', 'SILVLT', 2026, 'CT', 'RGREEN04', '2026-05-14', '2026-05-05', 2, 'Fleet inquiry refresh, follow-up scheduled.'),
-- DLR07 — 1 BMW lead
(25, 'DLR07', 'RPT', 'IX_50E', 2026, 'QF', 'DGOLD07',  '2026-05-12', '2026-05-08', 4, 'Repeat luxury buyer, evaluating iX EV vs X5.');

-- ── 4. New finance apps (5: 3 funded recently, 2 STALE in review) ──
INSERT INTO finance_app (finance_id, deal_number, customer_id, finance_type, lender_code, lender_name, app_status, amount_requested, amount_approved, apr_requested, apr_approved, term_months, monthly_payment, down_payment, credit_tier, submitted_ts, decision_ts, funded_ts) VALUES
-- 3 funded recently (closed loop)
('FIN71000001', 'DL01000200', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000200'), 'R', 'ALLY1', 'Ally Financial',         'FN', 40982.75, 40982.75, 6.500, 6.250, 60, 798.40,  10000.00, 'A',  '2026-04-28 10:30:00', '2026-04-28 14:00:00', '2026-05-02 09:30:00'),
('FIN71000002', 'DL01000201', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000201'), 'R', 'CHASE', 'Chase Auto Finance',     'FN', 34322.92, 34322.92, 6.250, 5.900, 60, 663.55,  14000.00, 'A',  '2026-05-03 11:00:00', '2026-05-03 14:30:00', '2026-05-07 09:45:00'),
('FIN71000003', 'DL01000202', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000202'), 'R', 'ALLY1', 'Ally Financial',         'FN', 45954.45, 45954.45, 6.500, 6.150, 72, 763.50,  12000.00, 'A',  '2026-05-08 10:15:00', '2026-05-08 13:50:00', '2026-05-10 10:00:00'),
-- 2 STALE submissions (>5 days, no decision yet) — for the "stuck in review" prompt
('FIN71000004', 'DL01000204', (SELECT customer_id FROM sales_deal WHERE deal_number='DL01000204'), 'R', 'WELLS', 'Wells Fargo Dealer Svcs','SB', 42982.75, NULL,     6.750, NULL,  NULL, NULL,    8000.00,  NULL, '2026-05-05 14:20:00', NULL,                  NULL),
('FIN71000005', 'DL06000200', (SELECT customer_id FROM sales_deal WHERE deal_number='DL06000200'), 'R', 'CPTL1', 'Capital One Auto',       'SB', 40048.64, NULL,     7.250, NULL,  NULL, NULL,    12000.00, NULL, '2026-05-04 11:30:00', NULL,                  NULL)
ON CONFLICT (finance_id) DO NOTHING;

-- ── 5. New warranty claims (3: fresh today / in review / closed last week) ──
-- VIN refs use V61 supplemental DLR01 vehicles known to exist.
INSERT INTO warranty_claim (claim_number, vin, dealer_code, claim_type, claim_date, repair_date, labor_amt, parts_amt, total_claim, claim_status, technician_id, repair_order_num, notes) VALUES
('CL710001', '1FTFW1E53NFA01501', 'DLR01', 'BA', '2026-05-11', NULL,         0.00,    0.00,    0.00, 'NW', NULL,       NULL,         'Customer reports infotainment screen flicker; appointment scheduled.'),
('CL710002', '1FMCU9J93NUA01501', 'DLR01', 'PT', '2026-05-06', '2026-05-08', 425.00,  680.00,  1105.00, 'AP', 'JPATTER1', 'RO01710002', 'Coolant temp sensor replaced; awaiting reimbursement.'),
('CL710003', '1FA6P8CF7N5A01501', 'DLR01', 'EX', '2026-05-02', '2026-05-04', 850.00,  1250.00, 2100.00, 'CL', 'JPATTER1', 'RO01710003', 'Mustang clutch slip — repaired and closed.')
ON CONFLICT (claim_number) DO NOTHING;

-- ── 6. New shipments (3: 1 arrived today / 2 in transit) ───────────
INSERT INTO shipment (shipment_id, carrier_code, carrier_name, origin_plant, dest_dealer, transport_mode, vehicle_count, ship_date, est_arrival_date, act_arrival_date, shipment_status) VALUES
('SH26-0000200', 'JBHT', 'J.B. Hunt Transport',     'DTP1', 'DLR01', 'TK', 3, '2026-05-05', '2026-05-11', '2026-05-11', 'DL'),
('SH26-0000201', 'JBHT', 'J.B. Hunt Transport',     'DTP1', 'DLR01', 'TK', 2, '2026-05-09', '2026-05-15', NULL,         'IT'),
('SH26-0000202', 'UPRR', 'Union Pacific Railroad',  'GTP1', 'DLR06', 'RL', 4, '2026-05-07', '2026-05-17', NULL,         'IT')
ON CONFLICT (shipment_id) DO NOTHING;

-- Link the arrived shipment's vehicles (must reference VINs created in step 1)
INSERT INTO shipment_vehicle (shipment_id, vin, load_sequence) VALUES
('SH26-0000200', '1FTFW1E53PFA01571', 1),
('SH26-0000200', '1FTFW1E53PFA01572', 2),
('SH26-0000200', '1FMCU9J93NUA01573', 3)
ON CONFLICT (shipment_id, vin) DO NOTHING;
