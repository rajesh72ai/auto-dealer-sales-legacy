-- V32: Add deals in AP and UW statuses (missing from current data)
-- Also add a few more across other statuses for richer demo
-- Using available vehicles not yet assigned to deals

-- DLR01: AP status deal
INSERT INTO sales_deal (deal_number, dealer_code, customer_id, vin, salesperson_id, sales_manager_id,
  deal_type, deal_status, vehicle_price, total_options, destination_fee, subtotal,
  trade_allow, trade_payoff, net_trade, rebates_applied, discount_amt, doc_fee,
  state_tax, county_tax, city_tax, title_fee, reg_fee, total_price,
  down_payment, amount_financed, front_gross, back_gross, total_gross, deal_date)
VALUES
('DL01000026', 'DLR01', 6, '1FTFW1E53NFA00102', 'TSMITH01', 'JPATTER1',
 'R', 'AP', 44970.00, 0.00, 1895.00, 46865.00,
 0.00, 0.00, 0.00, 0.00, 800.00, 799.00,
 1335.86, 461.34, 0.00, 7.20, 50.00, 48718.40,
 7000.00, 41718.40, 4297.00, 0.00, 4297.00, '2025-10-01'),

-- DLR02: AP status deal
('DL02000027', 'DLR02', 12, '3TMCZ5AN5NM300102', 'DJONES02', 'MSANTOS1',
 'R', 'AP', 37250.00, 0.00, 1335.00, 38585.00,
 10000.00, 3500.00, 6500.00, 0.00, 500.00, 199.00,
 2232.28, 0.00, 0.00, 15.00, 21.35, 34552.63,
 4000.00, 30552.63, 3225.00, 0.00, 3225.00, '2025-10-02'),

-- DLR03: UW status deal (unwound after delivery)
('DL03000028', 'DLR03', 18, '1HGCV3F16PA700102', 'KLEE0003', 'RNGUYEN3',
 'R', 'UW', 34850.00, 0.00, 1195.00, 36045.00,
 0.00, 0.00, 0.00, 0.00, 0.00, 599.00,
 2052.07, 256.51, 659.61, 4.00, 32.00, 39648.19,
 6000.00, 33648.19, 3137.00, 1800.00, 4937.00, '2025-08-15'),

-- DLR04: UW status deal
('DL04000029', 'DLR04', 24, '1G1ZD5STXNF200102', 'MBROWN04', 'WCLARK04',
 'R', 'UW', 28590.00, 0.00, 1195.00, 29785.00,
 0.00, 0.00, 0.00, 0.00, 0.00, 699.00,
 1219.36, 914.52, 457.26, 18.00, 20.00, 33113.14,
 5000.00, 28113.14, 2573.00, 1200.00, 3773.00, '2025-07-20'),

-- DLR05: AP status deal
('DL05000030', 'DLR05', 30, 'WBA5R1C50NFJ00103', 'PCHEN005', 'EHART005',
 'R', 'AP', 46400.00, 0.00, 995.00, 47395.00,
 18000.00, 9500.00, 8500.00, 0.00, 0.00, 599.00,
 2491.97, 0.00, 0.00, 25.00, 120.00, 42130.97,
 8000.00, 34130.97, 3712.00, 0.00, 3712.00, '2025-10-03');
