-- V40__seed_operations_data.sql
-- Seed stock_adjustment, stock_snapshot, pdi_schedule for vehicle operations screens.

-- ── Stock Adjustments (inventory corrections & status changes) ──────
-- adjust_type: RC=Recount, DM=Damage, LT=Lot Transfer, ST=Status Change, RV=Received Vehicle, WO=Write-Off
INSERT INTO stock_adjustment (dealer_code, vin, adjust_type, adjust_reason, old_status, new_status, adjusted_by, adjusted_ts) VALUES
('DLR01', '1FTFW1E53NFA00101', 'RC', 'Physical recount — found on back lot',          'IT', 'AV', 'JPATTER1', '2025-06-12 08:30:00'),
('DLR01', '1FTFW1E53NFA00103', 'DM', 'Hail damage during storm — moved to hold',      'AV', 'HD', 'JPATTER1', '2025-07-15 14:00:00'),
('DLR01', '1FM5K8GC7PGA00501', 'RV', 'Received from carrier — PDI pending',           'IT', 'AV', 'TSMITH01', '2025-08-01 09:15:00'),
('DLR01', '1FMCU9J93NUA00301', 'ST', 'Sold — deal DL01000001 delivered',              'AV', 'SD', 'TSMITH01', '2025-09-12 16:30:00'),
('DLR02', '4T1BF1FK5NU100101', 'ST', 'Sold — deal DL02000006 delivered',              'AV', 'SD', 'DJONES02', '2025-08-15 16:00:00'),
('DLR02', '2T3WFREV5NW200203', 'RV', 'Received from port — in transit cleared',       'IT', 'AV', 'MSANTOS1', '2025-09-10 10:00:00'),
('DLR02', '5TDBKRFH5NS400102', 'LT', 'Transferred to overflow lot',                  'AV', 'AV', 'MSANTOS1', '2025-09-20 11:30:00'),
('DLR03', '19XFC1F38NE500101', 'ST', 'Sold — deal DL03000011 delivered',              'AV', 'SD', 'KLEE0003', '2025-08-28 15:00:00'),
('DLR03', '7FARW2H93NE600101', 'ST', 'Sold — deal DL03000012 delivered',              'AV', 'SD', 'KLEE0003', '2025-09-15 14:00:00'),
('DLR03', '1HGCV3F16PA700101', 'DM', 'Minor scratch on front bumper — body shop',     'AV', 'HD', 'RNGUYEN3', '2025-10-05 08:45:00'),
('DLR03', '1HGCV3F16PA700101', 'ST', 'Body shop complete — returned to lot',          'HD', 'AV', 'RNGUYEN3', '2025-10-08 16:00:00'),
('DLR04', '1GCUYEED5NZ900101', 'ST', 'Sold — deal DL04000016 delivered',              'AV', 'SD', 'MBROWN04', '2025-09-18 15:30:00'),
('DLR04', '3GNAXKEV0PS100101', 'RC', 'Recount after lot reorganization',              'AV', 'AV', 'WCLARK04', '2025-10-01 09:00:00'),
('DLR04', '1GCUYEED5NZ900104', 'WO', 'Flood damage — insurance total loss',           'AV', 'HD', 'WCLARK04', '2025-10-15 11:00:00'),
('DLR05', 'WBA5R1C50NFJ00101', 'ST', 'Sold — deal DL05000021 delivered',              'AV', 'SD', 'PCHEN005', '2025-10-03 16:00:00'),
('DLR05', '5UXCR6C05NLL00201', 'ST', 'Sold — deal DL05000022 delivered',              'AV', 'SD', 'PCHEN005', '2025-10-07 14:00:00'),
('DLR05', 'WBY73AW05PFM00301', 'LT', 'Moved to indoor showroom',                     'AV', 'AV', 'EHART005', '2025-11-01 10:00:00'),
('DLR01', '1FTFW1E53PFA00202', 'ST', 'Customer deposit — allocated to deal',          'AV', 'AL', 'TSMITH01', '2026-03-25 09:00:00'),
('DLR02', '4T1BF1FK5PU200101', 'RC', 'Annual inventory audit — confirmed',            'AV', 'AV', 'MSANTOS1', '2026-03-28 08:00:00'),
('DLR03', '19XFC1F38NE500102', 'DM', 'Customer test drive — minor curb rash on wheel', 'AV', 'HD', 'RNGUYEN3', '2026-03-29 14:30:00');

-- ── Stock Snapshots (daily snapshots for last 7 days per dealer) ────
-- Provides data for stock trend charts. Using DLR01 Ford models as representative.
INSERT INTO stock_snapshot (snapshot_date, dealer_code, model_year, make_code, model_code, on_hand_count, in_transit_count, on_hold_count, total_value, avg_days_in_stock) VALUES
-- DLR01 — Ford
('2026-03-25', 'DLR01', 2025, 'FRD', 'F150XL', 3, 1, 1, 127470.00, 85),
('2026-03-26', 'DLR01', 2025, 'FRD', 'F150XL', 3, 1, 1, 127470.00, 86),
('2026-03-27', 'DLR01', 2025, 'FRD', 'F150XL', 3, 0, 1, 127470.00, 87),
('2026-03-28', 'DLR01', 2025, 'FRD', 'F150XL', 2, 0, 1, 84980.00,  88),
('2026-03-29', 'DLR01', 2025, 'FRD', 'F150XL', 2, 0, 1, 84980.00,  89),
('2026-03-30', 'DLR01', 2025, 'FRD', 'F150XL', 2, 0, 1, 84980.00,  90),
('2026-03-31', 'DLR01', 2025, 'FRD', 'F150XL', 2, 0, 1, 84980.00,  91),
('2026-03-25', 'DLR01', 2025, 'FRD', 'ESCSEL', 1, 0, 0, 34500.00,  72),
('2026-03-28', 'DLR01', 2025, 'FRD', 'ESCSEL', 1, 0, 0, 34500.00,  75),
('2026-03-31', 'DLR01', 2025, 'FRD', 'ESCSEL', 1, 0, 0, 34500.00,  78),
('2026-03-25', 'DLR01', 2026, 'FRD', 'F150XL', 2, 0, 0, 87980.00,  45),
('2026-03-28', 'DLR01', 2026, 'FRD', 'F150XL', 1, 0, 0, 43990.00,  48),
('2026-03-31', 'DLR01', 2026, 'FRD', 'F150XL', 1, 0, 0, 43990.00,  51),
-- DLR02 — Toyota
('2026-03-25', 'DLR02', 2025, 'TYT', 'CAMRYL', 2, 0, 0, 57710.00,  65),
('2026-03-28', 'DLR02', 2025, 'TYT', 'CAMRYL', 2, 0, 0, 57710.00,  68),
('2026-03-31', 'DLR02', 2025, 'TYT', 'CAMRYL', 2, 0, 0, 57710.00,  71),
('2026-03-25', 'DLR02', 2025, 'TYT', 'RAV4XP', 1, 1, 0, 35535.00,  55),
('2026-03-31', 'DLR02', 2025, 'TYT', 'RAV4XP', 1, 0, 0, 35535.00,  61),
('2026-03-25', 'DLR02', 2025, 'TYT', 'TACSR5', 1, 0, 0, 35250.00,  90),
('2026-03-31', 'DLR02', 2025, 'TYT', 'TACSR5', 1, 0, 0, 35250.00,  96),
-- DLR03 — Honda
('2026-03-25', 'DLR03', 2025, 'HND', 'CIVICX', 1, 0, 0, 27500.00,  50),
('2026-03-31', 'DLR03', 2025, 'HND', 'CIVICX', 1, 0, 1, 27500.00,  56),
('2026-03-25', 'DLR03', 2025, 'HND', 'CRV_EL', 1, 0, 0, 36600.00,  40),
('2026-03-31', 'DLR03', 2025, 'HND', 'CRV_EL', 1, 0, 0, 36600.00,  46),
-- DLR04 — Chevrolet
('2026-03-25', 'DLR04', 2025, 'CHV', 'SILVLT', 2, 0, 0, 88600.00,  70),
('2026-03-31', 'DLR04', 2025, 'CHV', 'SILVLT', 2, 0, 1, 88600.00,  76),
('2026-03-25', 'DLR04', 2025, 'CHV', 'MALIBU', 1, 0, 0, 27290.00,  55),
('2026-03-31', 'DLR04', 2025, 'CHV', 'MALIBU', 1, 0, 0, 27290.00,  61),
-- DLR05 — BMW
('2026-03-25', 'DLR05', 2025, 'BMW', '330IXD', 2, 0, 0, 89800.00,  35),
('2026-03-31', 'DLR05', 2025, 'BMW', '330IXD', 2, 0, 0, 89800.00,  41),
('2026-03-25', 'DLR05', 2025, 'BMW', 'X5XD40', 1, 0, 0, 65200.00,  28),
('2026-03-31', 'DLR05', 2025, 'BMW', 'X5XD40', 1, 0, 0, 65200.00,  34);

-- ── PDI Schedule (Pre-Delivery Inspections) ─────────────────────────
-- pdi_status: SC=Scheduled, IP=In Progress, PA=Passed, FL=Failed, WV=Waived
INSERT INTO pdi_schedule (vin, dealer_code, scheduled_date, technician_id, pdi_status, checklist_items, items_passed, items_failed, notes, completed_ts) VALUES
-- Completed PDIs
('1FTFW1E53NFA00101', 'DLR01', '2025-06-10', 'JPATTER1', 'PA', 25, 25, 0, 'All items passed — ready for lot', '2025-06-10 14:00:00'),
('1FTFW1E53NFA00102', 'DLR01', '2025-06-12', 'JPATTER1', 'PA', 25, 25, 0, 'Clean PDI', '2025-06-12 11:30:00'),
('4T1BF1FK5NU100101', 'DLR02', '2025-06-01', 'MSANTOS1', 'PA', 25, 25, 0, 'All checks passed', '2025-06-01 15:00:00'),
('2T3WFREV5NW200201', 'DLR02', '2025-07-10', 'MSANTOS1', 'PA', 25, 24, 1, 'Minor paint touch-up needed on door edge — corrected', '2025-07-10 16:30:00'),
('19XFC1F38NE500101', 'DLR03', '2025-06-08', 'RNGUYEN3', 'PA', 25, 25, 0, 'Perfect condition', '2025-06-08 13:00:00'),
('1GCUYEED5NZ900101', 'DLR04', '2025-06-03', 'WCLARK04', 'PA', 25, 25, 0, 'Ready for display', '2025-06-03 10:30:00'),
('WBA5R1C50NFJ00101', 'DLR05', '2025-05-10', 'EHART005', 'PA', 25, 25, 0, 'BMW standard PDI complete', '2025-05-10 14:45:00'),
-- Failed PDI (needs rework)
('1FTFW1E53NFA00103', 'DLR01', '2025-07-08', 'JPATTER1', 'FL', 25, 22, 3, 'FAILED: Windshield chip, tire pressure low, fluid top-off needed', '2025-07-08 16:00:00'),
('3GNAXKEV0PS100101', 'DLR04', '2025-08-20', 'WCLARK04', 'FL', 25, 23, 2, 'FAILED: Alignment off-spec, battery voltage low', '2025-08-20 15:00:00'),
-- In Progress
('1FM5K8GC7PGA00501', 'DLR01', '2026-03-30', 'JPATTER1', 'IP', 25, 18, 0, 'In progress — exterior and interior done, mechanical pending', NULL),
('2T3WFREV5NW200203', 'DLR02', '2026-03-31', 'MSANTOS1', 'IP', 25, 12, 0, 'Started morning shift — halfway through checklist', NULL),
-- Scheduled (upcoming)
('1FTFW1E53PFA00201', 'DLR01', '2026-04-01', NULL, 'SC', 25, 0, 0, NULL, NULL),
('5TDBKRFH5NS400102', 'DLR02', '2026-04-01', NULL, 'SC', 25, 0, 0, NULL, NULL),
('7FARW2H93NE600102', 'DLR03', '2026-04-02', NULL, 'SC', 25, 0, 0, NULL, NULL),
('1GCUYEED5NZ900102', 'DLR04', '2026-04-02', NULL, 'SC', 25, 0, 0, NULL, NULL),
('WBA5R1C50NFJ00102', 'DLR05', '2026-04-03', NULL, 'SC', 25, 0, 0, 'Awaiting technician assignment', NULL);
