-- V37__seed_audit_log.sql
-- Seed realistic audit log entries for dashboard "Recent Activity" panel.
-- Covers a mix of action types (INS, UPD, APV, DEL) across key business tables.

INSERT INTO audit_log (user_id, program_id, action_type, table_name, key_value, old_value, new_value, audit_ts) VALUES
-- Deal lifecycle activity
('ADMIN001', 'DealSvc',  'INS', 'sales_deal',     'D000000001', NULL, 'status=WS, customer=C0001, vin=1FMCU9J93NUA00101', '2026-03-28 08:15:00'),
('ADMIN001', 'DealSvc',  'UPD', 'sales_deal',     'D000000001', 'status=WS', 'status=NE', '2026-03-28 09:30:00'),
('ADMIN001', 'DealSvc',  'UPD', 'sales_deal',     'D000000001', 'status=NE', 'status=PA', '2026-03-28 10:45:00'),
('ADMIN001', 'DealSvc',  'APV', 'sales_deal',     'D000000001', 'status=PA', 'status=AP', '2026-03-28 14:20:00'),
('ADMIN001', 'DealSvc',  'UPD', 'sales_deal',     'D000000001', 'status=AP', 'status=CT', '2026-03-28 15:00:00'),
('ADMIN001', 'DealSvc',  'UPD', 'sales_deal',     'D000000001', 'status=CT', 'status=FI', '2026-03-28 16:10:00'),
('ADMIN001', 'DealSvc',  'UPD', 'sales_deal',     'D000000001', 'status=FI', 'status=DL', '2026-03-29 09:00:00'),

-- Customer and lead activity
('ADMIN001', 'CustSvc',  'INS', 'customer',       'C0025',      NULL, 'name=Robert Chen, phone=555-0199', '2026-03-29 10:15:00'),
('ADMIN001', 'LeadSvc',  'INS', 'customer_lead',  'L0026',      NULL, 'customer=C0025, status=NW, source=WALK-IN', '2026-03-29 10:20:00'),
('ADMIN001', 'LeadSvc',  'UPD', 'customer_lead',  'L0026',      'status=NW', 'status=CT', '2026-03-29 11:00:00'),

-- Finance activity
('ADMIN001', 'FinSvc',   'INS', 'finance_app',    'FA000022',   NULL, 'deal=D000000001, lender=Chase Auto, amount=35000', '2026-03-29 13:30:00'),
('ADMIN001', 'FinSvc',   'APV', 'finance_app',    'FA000022',   'status=SB', 'status=AP, rate=4.9%', '2026-03-29 15:45:00'),
('ADMIN001', 'FIPrdSvc', 'INS', 'fi_deal_product', 'FIP0036',   NULL, 'deal=D000000001, product=VSC, cost=1200', '2026-03-29 16:00:00'),

-- Vehicle and inventory activity
('ADMIN001', 'VehSvc',   'UPD', 'vehicle',        '1FMCU9J93NUA00101', 'status=AV', 'status=AL (allocated to deal D000000001)', '2026-03-30 08:30:00'),
('ADMIN001', 'StockSvc', 'UPD', 'stock_position', 'DLR01-2025-FRD-ESCSEL', 'on_hand=3', 'on_hand=2, allocated=1', '2026-03-30 08:31:00'),

-- Registration and warranty
('ADMIN001', 'RegSvc',   'INS', 'registration',   'REG0016',    NULL, 'vin=1FMCU9J93NUA00101, state=TX, plate=ABC-1234', '2026-03-30 10:00:00'),
('ADMIN001', 'WCSvc',    'INS', 'warranty_claim',  'WC0016',    NULL, 'vin=4T1BF1FK5NU100101, type=PT, complaint=Engine noise', '2026-03-30 11:30:00'),
('ADMIN001', 'WCSvc',    'UPD', 'warranty_claim',  'WC0016',    'status=NW', 'status=IP', '2026-03-30 14:00:00'),

-- Admin config changes
('ADMIN001', 'CfgSvc',   'UPD', 'system_config',  'MAX_DEAL_AGE_DAYS', 'value=90', 'value=120', '2026-03-31 08:00:00'),
('ADMIN001', 'PrcSvc',   'UPD', 'price_master',   'TYT-CAMRYL-2026', 'msrp=29500', 'msrp=29250 (spring promotion)', '2026-03-31 09:15:00');
