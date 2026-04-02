-- V27__seed_vehicle_details_and_supply_chain.sql
-- Seed vehicle options, status history, production orders, shipments, and PDI for Wave 5 testing.

-- ============================================================
-- VEHICLE OPTIONS (installed equipment per VIN)
-- ============================================================

-- DLR01 F-150 XL (1FTFW1E53NFA00101)
INSERT INTO vehicle_option (vin, option_code, option_desc, option_price, installed_flag) VALUES
('1FTFW1E53NFA00101', 'XLTPKG', 'XLT Chrome Appearance Package', 1995.00, 'Y'),
('1FTFW1E53NFA00101', 'TOWMAX', 'Max Trailer Tow Package', 1295.00, 'Y'),
('1FTFW1E53NFA00101', 'BEDLNR', 'Spray-In Bedliner', 595.00, 'Y'),
('1FTFW1E53NFA00101', 'NAVSYS', 'Navigation System w/ SYNC 4', 795.00, 'Y');

-- DLR01 Escape SEL (1FMCU9J93NUA00301)
INSERT INTO vehicle_option (vin, option_code, option_desc, option_price, installed_flag) VALUES
('1FMCU9J93NUA00301', 'STLPKG', 'SEL Tech Package', 1495.00, 'Y'),
('1FMCU9J93NUA00301', 'PANROF', 'Panoramic Moonroof', 1895.00, 'Y'),
('1FMCU9J93NUA00301', 'BOSND', 'B&O Sound System', 695.00, 'Y');

-- DLR02 Camry LE (4T1BF1FK5NU100101)
INSERT INTO vehicle_option (vin, option_code, option_desc, option_price, installed_flag) VALUES
('4T1BF1FK5NU100101', 'BSMPKG', 'Blind Spot Monitor Package', 595.00, 'Y'),
('4T1BF1FK5NU100101', 'ALWTR', 'All-Weather Floor Mats', 269.00, 'Y');

-- DLR03 Accord (1HGCV3F16PA700101)
INSERT INTO vehicle_option (vin, option_code, option_desc, option_price, installed_flag) VALUES
('1HGCV3F16PA700101', 'SENSPK', 'Honda Sensing Suite', 1000.00, 'Y'),
('1HGCV3F16PA700101', 'LEATH', 'Leather-Trimmed Interior', 1500.00, 'Y'),
('1HGCV3F16PA700101', 'WNTPKG', 'Winter Package (Heated Seats)', 395.00, 'Y');

-- ============================================================
-- VEHICLE STATUS HISTORY (audit trail of status changes)
-- ============================================================

-- DLR01 F-150 XL — full lifecycle
INSERT INTO vehicle_status_hist (vin, status_seq, old_status, new_status, changed_by, change_reason, changed_ts) VALUES
('1FTFW1E53NFA00101', 1, 'PR', 'AL', 'SYSTEM', 'Allocated to dealer DLR01', '2025-06-15 10:00:00'),
('1FTFW1E53NFA00101', 2, 'AL', 'IT', 'SYSTEM', 'Shipped via truck carrier JBHT', '2025-06-25 08:00:00'),
('1FTFW1E53NFA00101', 3, 'IT', 'DL', 'SYSTEM', 'Delivered to dealer dock', '2025-07-01 14:30:00'),
('1FTFW1E53NFA00101', 4, 'DL', 'AV', 'TSMITH01', 'PDI completed — all 42 items passed', '2025-07-05 16:00:00');

-- DLR01 Mustang GT — sold vehicle history
INSERT INTO vehicle_status_hist (vin, status_seq, old_status, new_status, changed_by, change_reason, changed_ts) VALUES
('1FA6P8CF7N5A00401', 1, 'PR', 'AL', 'SYSTEM', 'Allocated to dealer DLR01', '2025-04-15 09:00:00'),
('1FA6P8CF7N5A00401', 2, 'AL', 'AV', 'TSMITH01', 'Received and PDI passed', '2025-05-09 11:00:00'),
('1FA6P8CF7N5A00401', 3, 'AV', 'HD', 'JPATTER1', 'Customer deposit — hold for J. Henderson', '2025-09-05 15:00:00'),
('1FA6P8CF7N5A00401', 4, 'HD', 'AV', 'JPATTER1', 'Released — customer ready to close', '2025-09-10 09:00:00'),
('1FA6P8CF7N5A00401', 5, 'AV', 'SD', 'TSMITH01', 'Sold — Deal D000000003', '2025-09-12 16:30:00');

-- DLR02 Camry — received history
INSERT INTO vehicle_status_hist (vin, status_seq, old_status, new_status, changed_by, change_reason, changed_ts) VALUES
('4T1BF1FK5NU100101', 1, 'PR', 'AL', 'SYSTEM', 'Allocated to DLR02', '2025-05-05 08:00:00'),
('4T1BF1FK5NU100101', 2, 'AL', 'AV', 'DJONES02', 'Received at dock, PDI passed', '2025-06-02 13:00:00'),
('4T1BF1FK5NU100101', 3, 'AV', 'SD', 'DJONES02', 'Sold', '2025-08-15 16:00:00');

-- DLR03 Accord — lifecycle
INSERT INTO vehicle_status_hist (vin, status_seq, old_status, new_status, changed_by, change_reason, changed_ts) VALUES
('1HGCV3F16PA700101', 1, 'PR', 'AL', 'SYSTEM', 'Allocated to DLR03', '2025-08-22 10:00:00'),
('1HGCV3F16PA700101', 2, 'AL', 'AV', 'KLEE0003', 'Received and inspected', '2025-09-17 11:00:00');

-- ============================================================
-- PRODUCTION ORDERS (for testing supply chain flow)
-- ============================================================

INSERT INTO production_order (production_id, vin, model_year, make_code, model_code, plant_code, build_date, build_status, allocated_dealer, allocation_date, created_ts, updated_ts) VALUES
('PO25-0000001', '1FTFW1E53NFA00101', 2025, 'FRD', 'F150XL', 'DTP1', '2025-06-10', 'CM', 'DLR01', '2025-06-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('PO25-0000002', '1FA6P8CF7N5A00401', 2025, 'FRD', 'MUSTGT', 'DTP1', '2025-04-10', 'CM', 'DLR01', '2025-04-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('PO25-0000003', '4T1BF1FK5NU100101', 2025, 'TYT', 'CAMRYL', 'GTP1', '2025-05-01', 'CM', 'DLR02', '2025-05-05', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('PO25-0000004', '1HGCV3F16PA700101', 2026, 'HND', 'ACCORD', 'MRP1', '2025-08-20', 'CM', 'DLR03', '2025-08-22', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Note: Unallocated production orders (status PR) can be created via the UI
-- for testing the allocation flow. VIN is NOT NULL in the legacy schema.

-- ============================================================
-- SHIPMENTS (completed shipments for history)
-- ============================================================

INSERT INTO shipment (shipment_id, carrier_code, carrier_name, origin_plant, dest_dealer, transport_mode, vehicle_count, ship_date, est_arrival_date, act_arrival_date, shipment_status, created_ts, updated_ts) VALUES
('SH25-0000001', 'JBHT', 'J.B. Hunt Transport', 'DTP1', 'DLR01', 'TK', 2, '2025-06-25', '2025-06-28', '2025-07-01', 'DL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('SH25-0000002', 'UPRR', 'Union Pacific Railroad', 'GTP1', 'DLR02', 'RL', 1, '2025-05-20', '2025-05-27', '2025-06-01', 'DL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('SH25-0000003', 'JBHT', 'J.B. Hunt Transport', 'MRP1', 'DLR03', 'TK', 1, '2025-09-05', '2025-09-08', '2025-09-16', 'DL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Shipment vehicles
INSERT INTO shipment_vehicle (shipment_id, vin, load_sequence) VALUES
('SH25-0000001', '1FTFW1E53NFA00101', 1),
('SH25-0000001', '1FTFW1E53NFA00102', 2),
('SH25-0000002', '4T1BF1FK5NU100101', 1),
('SH25-0000003', '1HGCV3F16PA700101', 1);

-- Transit status history for shipment SH25-0000001
INSERT INTO transit_status (vin, status_seq, location_desc, status_code, edi_ref_num, status_ts, received_ts) VALUES
('1FTFW1E53NFA00101', 1, 'Departed Dearborn Plant', 'DP', 'EDI214-001', '2025-06-25 08:00:00', '2025-06-25 08:05:00'),
('1FTFW1E53NFA00101', 2, 'Arrived Kansas City Hub', 'AR', 'EDI214-002', '2025-06-27 14:00:00', '2025-06-27 14:10:00'),
('1FTFW1E53NFA00101', 3, 'Delivered to DLR01 Lakewood', 'DL', 'EDI214-003', '2025-07-01 14:30:00', '2025-07-01 14:35:00');

-- ============================================================
-- PDI SCHEDULES (completed inspections)
-- ============================================================

INSERT INTO pdi_schedule (vin, dealer_code, scheduled_date, technician_id, pdi_status, checklist_items, items_passed, items_failed, notes, completed_ts) VALUES
('1FTFW1E53NFA00101', 'DLR01', '2025-07-02', 'TSMITH01', 'CM', 42, 42, 0, 'All items passed. Vehicle ready for sale.', '2025-07-05 15:30:00'),
('1FTFW1E53NFA00102', 'DLR01', '2025-07-22', 'TSMITH01', 'CM', 42, 41, 1, 'Minor scratch on rear bumper — touched up.', '2025-07-25 11:00:00'),
('4T1BF1FK5NU100101', 'DLR02', '2025-05-30', 'DJONES02', 'CM', 42, 42, 0, 'Perfect condition.', '2025-06-02 14:00:00'),
('1HGCV3F16PA700101', 'DLR03', '2025-09-17', 'KLEE0003', 'CM', 42, 40, 2, 'Windshield chip repaired. Tire pressure adjusted.', '2025-09-17 10:00:00');

-- One pending PDI (for testing start/complete flow)
INSERT INTO pdi_schedule (vin, dealer_code, scheduled_date, pdi_status, checklist_items, items_passed, items_failed) VALUES
('1FM5K8GC7PGA00501', 'DLR01', '2026-04-01', 'SC', 42, 0, 0);

-- ============================================================
-- STOCK TRANSFERS (one completed, one pending)
-- ============================================================

INSERT INTO stock_transfer (from_dealer, to_dealer, vin, transfer_status, requested_by, approved_by, requested_ts, approved_ts, completed_ts) VALUES
('DLR03', 'DLR01', '19XFC1F38NE500102', 'CM', 'JPATTER1', 'RNGUYEN3', '2025-09-01 10:00:00', '2025-09-02 09:00:00', '2025-09-05 14:00:00');

-- ============================================================
-- STOCK ADJUSTMENTS (sample audit entries)
-- ============================================================

INSERT INTO stock_adjustment (dealer_code, vin, adjust_type, adjust_reason, old_status, new_status, adjusted_by, adjusted_ts) VALUES
('DLR01', '1FTFW1E53NFA00102', 'PH', 'Annual physical inventory count', 'AV', 'AV', 'JPATTER1', '2025-12-31 16:00:00'),
('DLR01', '1FMCU9J93NUA00302', 'RC', 'Reclassified from demo to available', 'AV', 'AV', 'JPATTER1', '2026-01-15 10:00:00');
