-- V30: Seed customer leads across all statuses and dealers
-- Statuses: NW, CT, QF, PR, WN, LS, DD
-- Sources: WEB, WLK, REF, RPT, ADV

INSERT INTO customer_lead (customer_id, dealer_code, lead_source, interest_model, interest_year, lead_status, assigned_sales, follow_up_date, last_contact_dt, contact_count, notes) VALUES
-- DLR01 leads
(1,  'DLR01', 'WEB', 'F150XL', 2025, 'WN', 'TSMITH01', '2025-07-10', '2025-07-08', 5, 'Customer purchased 2025 F-150 XLT. Great experience.'),
(2,  'DLR01', 'WLK', 'MUSTGT', 2025, 'WN', 'TSMITH01', '2025-06-15', '2025-06-12', 4, 'Walk-in buyer, closed on Mustang GT same week.'),
(3,  'DLR01', 'REF', 'EXPLLT', 2026, 'PR', 'TSMITH01', '2025-10-15', '2025-10-01', 3, 'Referred by Michael Henderson. Wants Explorer Limited.'),
(4,  'DLR01', 'ADV', 'ESCSEL', 2025, 'CT', 'TSMITH01', '2025-10-10', '2025-10-03', 2, 'Responded to TV ad. Interested in Escape SEL.'),
(5,  'DLR01', 'WEB', 'F150XL', 2026, 'NW', 'TSMITH01', '2025-10-08', NULL, 0, 'Online inquiry for 2026 F-150. No contact yet.'),
(6,  'DLR01', 'RPT', 'EXPLLT', 2026, 'LS', 'TSMITH01', '2025-08-20', '2025-08-18', 3, 'Repeat customer, went with competitor pricing.'),

-- DLR02 leads
(7,  'DLR02', 'WLK', 'CAMRYL', 2025, 'WN', 'DJONES02', '2025-07-05', '2025-07-03', 4, 'Walk-in purchased Camry LE.'),
(8,  'DLR02', 'WEB', 'RAV4XP', 2025, 'QF', 'DJONES02', '2025-10-12', '2025-10-05', 2, 'Pre-approved financing, shopping RAV4 XLE Premium.'),
(9,  'DLR02', 'REF', 'HGHLXL', 2025, 'CT', 'DJONES02', '2025-10-14', '2025-10-02', 1, 'Referral from Patricia Anderson. Wants Highlander.'),
(10, 'DLR02', 'ADV', 'TACSR5', 2025, 'NW', 'DJONES02', '2025-10-09', NULL, 0, 'Mailer response, interested in Tacoma SR5.'),
(11, 'DLR02', 'WEB', 'CAMRYL', 2026, 'DD', 'DJONES02', '2025-05-20', '2025-05-15', 1, 'No response after initial contact. Dead lead.'),

-- DLR03 leads
(13, 'DLR03', 'WEB', 'CIVICX', 2025, 'WN', 'KLEE0003', '2025-07-15', '2025-07-12', 5, 'Purchased Civic EX after test drive.'),
(14, 'DLR03', 'WLK', 'CRV_EL', 2025, 'WN', 'KLEE0003', '2025-08-01', '2025-07-28', 3, 'Walk-in, closed on CR-V EX-L.'),
(15, 'DLR03', 'REF', 'ACCORD', 2026, 'PR', 'KLEE0003', '2025-10-18', '2025-10-08', 2, 'Wants 2026 Accord Sport. Reviewing financing options.'),
(16, 'DLR03', 'ADV', 'PILTEX', 2025, 'QF', 'KLEE0003', '2025-10-11', '2025-10-06', 2, 'Qualified buyer for Pilot EX-L, credit approved.'),
(17, 'DLR03', 'WEB', 'CIVICX', 2025, 'LS', 'KLEE0003', '2025-09-15', '2025-09-10', 4, 'Lost to competitor Honda dealer across town.'),

-- DLR04 leads
(19, 'DLR04', 'WLK', 'SILVLT', 2025, 'WN', 'MBROWN04', '2025-07-01', '2025-06-28', 4, 'Walk-in purchased Silverado 1500 LT.'),
(20, 'DLR04', 'WEB', 'EQNOLT', 2026, 'CT', 'MBROWN04', '2025-10-13', '2025-10-07', 2, 'Interested in 2026 Equinox LT. Scheduling test drive.'),
(21, 'DLR04', 'REF', 'SILVLT', 2025, 'NW', 'MBROWN04', '2025-10-10', NULL, 0, 'Referred by Brandon Jackson. Fleet inquiry.'),
(22, 'DLR04', 'RPT', 'MALIBU', 2025, 'DD', 'MBROWN04', '2025-04-10', '2025-04-05', 1, 'Repeat customer, decided to keep current vehicle.'),

-- DLR05 leads
(25, 'DLR05', 'WEB', '330IXD', 2025, 'WN', 'PCHEN005', '2025-06-10', '2025-06-08', 3, 'Purchased 330i xDrive after online inquiry.'),
(26, 'DLR05', 'WLK', 'X5XD40', 2025, 'PR', 'PCHEN005', '2025-10-16', '2025-10-09', 2, 'Negotiating X5 xDrive40i. Has trade-in.'),
(27, 'DLR05', 'REF', 'IX_50E', 2026, 'QF', 'PCHEN005', '2025-10-15', '2025-10-04', 1, 'Interested in iX xDrive50. Pre-qualified for lease.'),
(28, 'DLR05', 'ADV', '330IXD', 2025, 'NW', 'PCHEN005', '2025-10-09', NULL, 0, 'Billboard ad response. Wants 330i info.'),
(29, 'DLR05', 'WEB', 'X5XD40', 2025, 'LS', 'PCHEN005', '2025-08-25', '2025-08-20', 3, 'Went with Mercedes GLE instead.');
