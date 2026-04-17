-- ==========================================================================
-- V62: 48 new customers + 60 leads with persona-aware distribution
-- Existing customers: IDs 1-30 (V18). New customers will be IDs 31-78.
-- Leads use subquery on email to fetch newly-minted customer_ids since
-- customer.customer_id is GENERATED ALWAYS AS IDENTITY.
-- ==========================================================================

-- ── New Customers (48 across 12 dealers) ────────────────────────────
INSERT INTO customer (first_name, last_name, middle_init, date_of_birth, ssn_last4, drivers_license, dl_state, address_line1, city, state_code, zip_code, cell_phone, email, employer_name, annual_income, customer_type, source_code, dealer_code, assigned_sales) VALUES
-- DLR01 +2
('Nathan',   'Garza',     'R', '1986-04-20', '1122', 'CO-556-7788', 'CO', '2890 S Kipling St',      'Lakewood',    'CO', '80227', '3035551031', 'ngarza@email.com',    'Kaiser Permanente',   88000.00,  'I', 'WEB', 'DLR01', 'TSMITH01'),
('Olivia',   'Bennett',   'M', '1994-08-15', '2233', 'CO-667-8899', 'CO', '6500 W 44th Ave',        'Wheat Ridge', 'CO', '80033', '3035551032', 'obennett@email.com',  'DaVita',              72000.00,  'I', 'REF', 'DLR01', 'JDOE0001'),
-- DLR02 +2
('Gerald',   'Whitley',   'P', '1970-11-25', '3344', 'IN-3312-8890', 'IN', '1220 W 86th St',        'Indianapolis','IN', '46260', '3175552041', 'gwhitley@email.com',  'Anthem Inc',          125000.00, 'I', 'RPT', 'DLR02', 'DJONES02'),
('Rachel',   'Tomlin',    'E', '1988-02-09', '4455', 'IN-4423-9901', 'IN', '2020 Meridian St N',    'Carmel',      'IN', '46032', '3175552042', 'rtomlin@email.com',   'Roche Diagnostics',   95000.00,  'I', 'WEB', 'DLR02', 'APARK002'),
-- DLR03 +2
('Isaac',    'Meyer',     'D', '1982-07-03', '5566', 'AZ-D78901234', 'AZ', '1850 W Chandler Blvd',  'Chandler',    'AZ', '85224', '4805553051', 'imeyer@email.com',    'Freeport-McMoRan',    82000.00,  'I', 'WLK', 'DLR03', 'KLEE0003'),
('Hannah',   'Okafor',    'C', '1996-12-14', '6677', 'AZ-D89012345', 'AZ', '2400 S Alma School Rd', 'Chandler',    'AZ', '85286', '4805553052', 'hokafor@email.com',   'Honeywell Aerospace', 78000.00,  'I', 'ADV', 'DLR03', 'LWONG003'),
-- DLR04 +2
('Terrell',  'Dawson',    'A', '1974-10-30', '7788', 'GA-067890123', 'GA', '1890 Howell Mill Rd',   'Atlanta',     'GA', '30318', '4045554061', 'tdawson@email.com',   'The Home Depot',      98000.00,  'I', 'WEB', 'DLR04', 'MBROWN04'),
('Crystal',  'Jefferson', 'L', '1991-06-17', '8899', 'GA-068901234', 'GA', '650 Windsor Pkwy',      'Atlanta',     'GA', '30342', '4045554062', 'cjefferson@email.com','Turner Broadcasting', 84000.00,  'I', 'REF', 'DLR04', 'RGREEN04'),
-- DLR05 +2
('Preston',  'Ashworth',  'G', '1968-01-22', '9900', 'CT-212345678', 'CT', '88 Beachside Ave',      'Westport',    'CT', '06880', '2035555071', 'pashworth@email.com', 'Point72 Asset Mgmt',  285000.00, 'I', 'RPT', 'DLR05', 'PCHEN005'),
('Valentina','Moreno',    'S', '1985-09-04', '0011', 'CT-223456789', 'CT', '320 Round Hill Rd',     'Greenwich',   'CT', '06831', '2035555072', 'vmoreno@email.com',   'Bridgewater Associates',195000.00,'I', 'WEB', 'DLR05', 'SLEE0005'),
-- DLR06 +6 (Plainfield NJ — Volume leader)
('Keith',    'Donovan',   'M', '1979-05-28', '1111', 'NJ-D10001001','NJ',  '88 South Ave',          'Plainfield',  'NJ', '07060', '9085556001', 'kdonovan@email.com',  'Prudential Financial',89000.00,  'I', 'WLK', 'DLR06', 'JSMITH06'),
('Angela',   'Stapleton', 'B', '1990-11-11', '2222', 'NJ-D20002002','NJ',  '1200 Terrill Rd',       'Scotch Plains','NJ','07076', '9085556002', 'astapleton@email.com','Verizon Wireless',    82000.00,  'I', 'WEB', 'DLR06', 'TBROWN06'),
('Lamar',    'Okonkwo',   'D', '1983-03-07', '3333', 'NJ-D30003003','NJ',  '450 Park Ave',          'Scotch Plains','NJ','07076', '9085556003', 'lokonkwo@email.com',  'Merck & Co',          112000.00, 'B', 'REF', 'DLR06', 'JSMITH06'),
('Patricia', 'Nolan',     NULL,'1987-07-19', '4444', 'NJ-D40004004','NJ',  '2100 Stelton Rd',       'Piscataway',  'NJ', '08854', '9085556004', 'pnolan@email.com',    'Rutgers University',  73000.00,  'I', 'ADV', 'DLR06', 'TBROWN06'),
('Martin',   'Kowalski',  'J', '1965-12-02', '5555', 'NJ-D50005005','NJ',  '975 Mountain Ave',      'Mountainside','NJ', '07092', '9085556005', 'mkowalski@email.com', 'Retired',             68000.00,  'I', 'RPT', 'DLR06', 'JSMITH06'),
('Sofia',    'Delgado',   'R', '1998-04-14', '6666', 'NJ-D60006006','NJ',  '50 Route 27',           'Edison',      'NJ', '08817', '9085556006', 'sdelgado@email.com',  'Johnson & Johnson',   76000.00,  'I', 'WEB', 'DLR06', 'TBROWN06'),
-- DLR07 +5 (Charlotte BMW — Luxury)
('Randall',  'Prescott',  'H', '1969-09-08', '7777', 'NC-070007000','NC',  '2200 Queens Rd',        'Charlotte',   'NC', '28207', '7045557001', 'rprescott@email.com', 'Bank of America',     210000.00, 'I', 'RPT', 'DLR07', 'DGOLD07'),
('Cordelia', 'Ferguson',  'A', '1977-02-25', '8880', 'NC-080008000','NC',  '4520 Piedmont Row Dr',  'Charlotte',   'NC', '28210', '7045557002', 'cferguson@email.com', 'Wells Fargo',         155000.00, 'I', 'REF', 'DLR07', 'CGREY07'),
('Barrington','Hayes',    'W', '1972-06-12', '9991', 'NC-090009000','NC',  '300 S Tryon St',        'Charlotte',   'NC', '28202', '7045557003', 'bhayes@email.com',    'Hayes Consulting LLC',275000.00, 'B', 'RPT', 'DLR07', 'DGOLD07'),
('Giselle',  'Thornburg', 'E', '1989-10-05', '1012', 'NC-100010001','NC',  '1615 Providence Rd',    'Charlotte',   'NC', '28207', '7045557004', 'gthornburg@email.com','Duke Energy',         125000.00, 'I', 'WEB', 'DLR07', 'CGREY07'),
('Maxwell',  'Atherton',  'P', '1974-03-30', '1113', 'NC-110011001','NC',  '750 Fairview Rd',       'Charlotte',   'NC', '28210', '7045557005', 'matherton@email.com', 'Atherton Orthopedics',320000.00, 'I', 'REF', 'DLR07', 'DGOLD07'),
-- DLR08 +6 (Riverside Honda — Struggling)
('Teresa',   'Valadez',   'G', '1984-08-22', '1214', 'CA-T10008001','CA',  '3800 Arlington Ave',    'Riverside',   'CA', '92506', '9515558001', 'tvaladez@email.com',  'Riverside County',    62000.00,  'I', 'WLK', 'DLR08', 'KSANT08'),
('Dominic',  'Rasmussen', 'J', '1992-01-16', '1315', 'CA-D20008002','CA',  '5600 Canyon Crest Dr',  'Riverside',   'CA', '92507', '9515558002', 'drasmussen@email.com','UC Riverside',        58000.00,  'I', 'WEB', 'DLR08', 'TLOW08'),
('Jasmine',  'Peacock',   NULL,'1997-05-11', '1416', 'CA-P30008003','CA',  '2400 Magnolia Ave',     'Riverside',   'CA', '92501', '9515558003', 'jpeacock@email.com',  'Starbucks',           39000.00,  'I', 'ADV', 'DLR08', 'KSANT08'),
('Ruben',    'Alcantar',  'E', '1976-10-04', '1517', 'CA-A40008004','CA',  '1100 University Ave',   'Riverside',   'CA', '92507', '9515558004', 'ralcantar@email.com', 'Self-Employed',       71000.00,  'B', 'REF', 'DLR08', 'TLOW08'),
('Cheryl',   'Shoemaker', 'D', '1963-12-18', '1618', 'CA-S50008005','CA',  '9020 Magnolia Ave',     'Riverside',   'CA', '92503', '9515558005', 'cshoemaker@email.com','Retired',             48000.00,  'I', 'RPT', 'DLR08', 'KSANT08'),
('Jarrell',  'Whitfield', 'T', '1990-06-27', '1719', 'CA-W60008006','CA',  '3110 Central Ave',      'Riverside',   'CA', '92506', '9515558006', 'jwhitfield08@email.com','Amazon Fulfillment',51000.00,  'I', 'WEB', 'DLR08', 'TLOW08'),
-- DLR09 +6 (Dallas Chevrolet — Warranty hotspot)
('Garrett',  'Thibodaux', 'L', '1982-04-09', '1820', 'TX-T10009001','TX',  '6200 Gaston Ave',       'Dallas',      'TX', '75214', '2145559001', 'gthibodaux@email.com','AT&T',                92000.00,  'I', 'WLK', 'DLR09', 'MJOHN09'),
('Monique',  'Spellman',  'A', '1995-08-03', '1921', 'TX-S20009002','TX',  '3000 Blackburn St',     'Dallas',      'TX', '75204', '2145559002', 'mspellman@email.com', 'Texas Instruments',   88000.00,  'I', 'WEB', 'DLR09', 'BFOSTER9'),
('Clayton',  'Pendergrass','K','1971-11-21', '2022', 'TX-P30009003','TX',  '12100 Preston Rd',      'Dallas',      'TX', '75230', '2145559003', 'cpendergrass@email.com','Pendergrass Drilling',185000.00,'B', 'RPT', 'DLR09', 'MJOHN09'),
('Whitney',  'Ambrose',   NULL,'1988-02-07', '2123', 'TX-A40009004','TX',  '5200 Ross Ave',         'Dallas',      'TX', '75206', '2145559004', 'wambrose@email.com',  'Baylor Scott & White',76000.00,  'I', 'REF', 'DLR09', 'BFOSTER9'),
('Darnell',  'Odom',      'B', '1978-07-14', '2224', 'TX-O50009005','TX',  '8400 Preston Rd',       'Dallas',      'TX', '75225', '2145559005', 'dodom@email.com',     'American Airlines',   84000.00,  'I', 'WEB', 'DLR09', 'MJOHN09'),
('Latoya',   'Washburn',  'R', '1993-10-28', '2325', 'TX-W60009006','TX',  '1600 Commerce St',      'Dallas',      'TX', '75201', '2145559006', 'lwashburn@email.com', 'Southwest Airlines',  67000.00,  'I', 'ADV', 'DLR09', 'BFOSTER9'),
-- DLR10 +5 (Boise Toyota — F&I powerhouse)
('Trevor',   'Bancroft',  'J', '1980-03-16', '2426', 'ID-B10010001','ID',  '4500 N Bogus Basin Rd', 'Boise',       'ID', '83702', '2085550101', 'tbancroft@email.com', 'Micron Technology',   105000.00, 'I', 'WEB', 'DLR10', 'SMART10'),
('Melinda',  'Engstrom',  'H', '1987-09-02', '2527', 'ID-E20010002','ID',  '1200 Harrison Blvd',    'Boise',       'ID', '83702', '2085550102', 'mengstrom@email.com', 'St Luke''s Health',     94000.00, 'I', 'REF', 'DLR10', 'EYOUNG10'),
('Branson',  'Kirkpatrick','M','1973-05-29', '2628', 'ID-K30010003','ID',  '800 W State St',        'Eagle',       'ID', '83616', '2085550103', 'bkirkpatrick@email.com','Kirkpatrick & Assoc',145000.00,'B', 'RPT', 'DLR10', 'SMART10'),
('Annalise', 'Redmond',   NULL,'1991-12-10', '2729', 'ID-R40010004','ID',  '3600 Broadway Ave',     'Boise',       'ID', '83706', '2085550104', 'aredmond@email.com',  'Albertsons HQ',       82000.00,  'I', 'WLK', 'DLR10', 'EYOUNG10'),
('Corbin',   'Fairchild', 'N', '1966-08-05', '2830', 'ID-F50010005','ID',  '6800 W Overland Rd',    'Boise',       'ID', '83709', '2085550105', 'cfairchild@email.com','Boise Cascade',       115000.00, 'I', 'WEB', 'DLR10', 'SMART10'),
-- DLR11 +5 (Madison Ford — Baseline)
('Holden',   'Vanderberg','C', '1984-11-18', '2931', 'WI-V10011001','WI',  '2200 E Washington Ave', 'Madison',     'WI', '53704', '6085550201', 'hvanderberg@email.com','Epic Systems',        96000.00,  'I', 'WLK', 'DLR11', 'JWOOD11'),
('Brielle',  'Sorensen',  'A', '1990-02-23', '3032', 'WI-S20011002','WI',  '410 State St',          'Madison',     'WI', '53703', '6085550202', 'bsorensen@email.com', 'UW-Madison',          74000.00,  'I', 'WEB', 'DLR11', 'HKNIGH1'),
('Reginald', 'Bouchard',  'T', '1975-06-07', '3133', 'WI-B30011003','WI',  '1800 University Bay Dr','Madison',     'WI', '53705', '6085550203', 'rbouchard@email.com', 'American Family Ins',105000.00, 'I', 'REF', 'DLR11', 'JWOOD11'),
('Camila',   'Arellano',  NULL,'1993-10-14', '3234', 'WI-A40011004','WI',  '5400 Odana Rd',         'Madison',     'WI', '53719', '6085550204', 'carellano@email.com', 'Exact Sciences',      68000.00,  'I', 'ADV', 'DLR11', 'HKNIGH1'),
('Harrison', 'Underwood', 'P', '1968-01-05', '3335', 'WI-U50011005','WI',  '700 John Nolen Dr',     'Madison',     'WI', '53713', '6085550205', 'hunderwood@email.com','CUNA Mutual Group',   118000.00, 'B', 'RPT', 'DLR11', 'JWOOD11'),
-- DLR12 +5 (Albany Honda — Baseline)
('Darius',   'McNamara',  'E', '1981-07-26', '3436', 'NY-M10012001','NY',  '1220 Western Ave',      'Albany',      'NY', '12203', '5185550301', 'dmcnamara@email.com', 'NY State Dept of Taxation',89000.00,'I','WLK', 'DLR12', 'GLOPE12'),
('Autumn',   'Brockway',  NULL,'1989-04-01', '3537', 'NY-B20012002','NY',  '88 State St',           'Albany',      'NY', '12207', '5185550302', 'abrockway@email.com', 'Empire State Plaza',  72000.00,  'I', 'WEB', 'DLR12', 'OWARD12'),
('Kendrick', 'Sumner',    'O', '1977-10-19', '3638', 'NY-S30012003','NY',  '2400 Central Ave',      'Albany',      'NY', '12205', '5185550303', 'ksumner@email.com',   'GlobalFoundries',     96000.00,  'I', 'REF', 'DLR12', 'GLOPE12'),
('Priscilla','Yeager',    'R', '1995-08-12', '3739', 'NY-Y40012004','NY',  '450 Madison Ave',       'Albany',      'NY', '12208', '5185550304', 'pyeager@email.com',   'Albany Medical Center',62000.00, 'I', 'ADV', 'DLR12', 'OWARD12'),
('Silas',    'Greenlee',  'B', '1972-05-24', '3840', 'NY-G50012005','NY',  '1800 Route 9',          'Clifton Park','NY', '12065', '5185550305', 'sgreenlee@email.com', 'GE Research',         134000.00, 'I', 'RPT', 'DLR12', 'GLOPE12');

-- ── Leads on EXISTING customers (IDs 1-30) ──────────────────────────
-- Fresh leads + stale leads (for DLR03, DLR08 struggling persona signal)
INSERT INTO customer_lead (customer_id, dealer_code, lead_source, interest_model, interest_year, lead_status, assigned_sales, follow_up_date, last_contact_dt, contact_count, notes) VALUES
-- DLR01 fresh (volume leader — healthy follow-up)
(1,  'DLR01', 'WEB', 'F150XL', 2026, 'QF', 'TSMITH01', '2026-04-20', '2026-04-12', 3, 'Qualified, wants 2026 F-150 XLT with tow package.'),
(2,  'DLR01', 'WLK', 'EXPLLT', 2026, 'PR', 'JDOE0001', '2026-04-18', '2026-04-10', 2, 'Negotiating Explorer Limited, has trade-in consideration.'),
-- DLR02 fresh
(7,  'DLR02', 'REF', 'HGHLXL', 2025, 'CT', 'DJONES02', '2026-04-22', '2026-04-15', 1, 'Initial contact, wants Highlander XLE info.'),
(8,  'DLR02', 'WEB', 'RAV4XP', 2025, 'QF', 'APARK002', '2026-04-19', '2026-04-13', 2, 'Pre-approved financing, test drive scheduled.'),
-- DLR03 STALE (struggling persona)
(13, 'DLR03', 'WEB', 'CIVICX', 2025, 'CT', 'KLEE0003', '2026-01-20', '2025-12-15', 1, 'Initial contact, no response for 3+ months. Needs re-engagement.'),
(14, 'DLR03', 'WLK', 'CRV_EL', 2025, 'DD', 'LWONG003', '2025-11-15', '2025-11-10', 2, 'Went dark after test drive. Dead lead.'),
(15, 'DLR03', 'REF', 'ACCORD', 2026, 'LS', 'KLEE0003', '2026-02-10', '2026-02-05', 3, 'Lost to competitor Honda dealer with better pricing.'),
(16, 'DLR03', 'ADV', 'PILTEX', 2025, 'CT', 'LWONG003', '2026-02-28', '2026-02-20', 1, 'No follow-up in 50+ days. Needs outreach.'),
-- DLR04 healthy
(19, 'DLR04', 'WEB', 'EQNOLT', 2026, 'QF', 'MBROWN04', '2026-04-21', '2026-04-14', 2, 'Qualified for 2026 Equinox LT EV.'),
(20, 'DLR04', 'REF', 'SILVLT', 2025, 'PR', 'RGREEN04', '2026-04-17', '2026-04-11', 3, 'Fleet manager wants 3 Silverados.'),
-- DLR05 F&I (high conversion)
(25, 'DLR05', 'WEB', 'X5XD40', 2025, 'WN', 'PCHEN005', '2026-04-10', '2026-04-05', 4, 'Closed X5 with full F&I package.'),
(26, 'DLR05', 'REF', 'IX_50E', 2026, 'QF', 'SLEE0005', '2026-04-23', '2026-04-16', 2, 'Interested in iX xDrive50, has trade.'),
(27, 'DLR05', 'RPT', '330IXD', 2025, 'PR', 'PCHEN005', '2026-04-19', '2026-04-14', 3, 'Repeat BMW customer, negotiating lease.'),
-- Additional existing-customer leads for various dealers
(3,  'DLR01', 'ADV', 'MUSTGT', 2025, 'WN', 'TSMITH01', '2026-03-20', '2026-03-15', 3, 'Purchased Mustang GT via promo.'),
(9,  'DLR02', 'WLK', 'TACSR5', 2025, 'NW', 'DJONES02', '2026-04-14', NULL,        0, 'Walk-in, no contact yet. Fresh lead.'),
(21, 'DLR04', 'WEB', 'MALIBU', 2025, 'DD', 'MBROWN04', '2025-12-20', '2025-12-15', 1, 'No response. Dead.'),
(29, 'DLR05', 'ADV', 'X5XD40', 2025, 'CT', 'SLEE0005', '2026-04-15', '2026-04-08', 1, 'Billboard response, evaluating X5.');

-- ── Leads on NEW customers (fetch IDs via email subquery) ───────────
-- DLR06 leads (volume leader — healthy mix)
INSERT INTO customer_lead (customer_id, dealer_code, lead_source, interest_model, interest_year, lead_status, assigned_sales, follow_up_date, last_contact_dt, contact_count, notes) VALUES
((SELECT customer_id FROM customer WHERE email='kdonovan@email.com'),    'DLR06', 'WLK', 'F150XL', 2026, 'WN', 'JSMITH06', '2026-01-16', '2026-01-12', 4, 'Purchased F-150 XLT.'),
((SELECT customer_id FROM customer WHERE email='astapleton@email.com'),  'DLR06', 'WEB', 'ESCSEL', 2025, 'WN', 'TBROWN06', '2026-03-22', '2026-03-18', 3, 'Purchased Escape SEL hybrid.'),
((SELECT customer_id FROM customer WHERE email='lokonkwo@email.com'),    'DLR06', 'REF', 'F150XL', 2026, 'QF', 'JSMITH06', '2026-04-22', '2026-04-14', 2, 'Fleet inquiry, 5 F-150s.'),
((SELECT customer_id FROM customer WHERE email='pnolan@email.com'),      'DLR06', 'ADV', 'EXPLLT', 2026, 'PR', 'TBROWN06', '2026-04-19', '2026-04-12', 2, 'Negotiating Explorer Limited.'),
((SELECT customer_id FROM customer WHERE email='mkowalski@email.com'),   'DLR06', 'RPT', 'ESCSEL', 2025, 'CT', 'JSMITH06', '2026-04-20', '2026-04-15', 1, 'Retired buyer, wants reliable hybrid.'),
((SELECT customer_id FROM customer WHERE email='sdelgado@email.com'),    'DLR06', 'WEB', 'MUSTGT', 2025, 'NW', 'TBROWN06', '2026-04-16', NULL,         0, 'Online inquiry, no contact yet.'),
-- DLR07 leads (luxury)
((SELECT customer_id FROM customer WHERE email='rprescott@email.com'),   'DLR07', 'RPT', '330IXD', 2025, 'WN', 'DGOLD07',  '2025-12-24', '2025-12-22', 3, 'Repeat BMW buyer, closed 330i.'),
((SELECT customer_id FROM customer WHERE email='cferguson@email.com'),   'DLR07', 'REF', 'X5XD40', 2025, 'WN', 'CGREY07',  '2026-02-28', '2026-02-25', 4, 'Purchased X5 with premium package.'),
((SELECT customer_id FROM customer WHERE email='bhayes@email.com'),      'DLR07', 'RPT', 'X5XD40', 2025, 'WN', 'DGOLD07',  '2026-01-18', '2026-01-16', 3, 'Fleet buyer for executives.'),
((SELECT customer_id FROM customer WHERE email='gthornburg@email.com'),  'DLR07', 'WEB', 'IX_50E', 2026, 'PR', 'CGREY07',  '2026-04-21', '2026-04-15', 2, 'Evaluating iX xDrive50 lease.'),
((SELECT customer_id FROM customer WHERE email='matherton@email.com'),   'DLR07', 'REF', 'IX_50E', 2026, 'QF', 'DGOLD07',  '2026-04-22', '2026-04-14', 2, 'Qualified for premium EV lease.'),
-- DLR08 leads STALE (struggling persona)
((SELECT customer_id FROM customer WHERE email='tvaladez@email.com'),    'DLR08', 'WLK', 'CIVICX', 2025, 'DD', 'KSANT08',  '2025-10-15', '2025-10-05', 1, 'Walked out, no follow-up. Dead.'),
((SELECT customer_id FROM customer WHERE email='drasmussen@email.com'),  'DLR08', 'WEB', 'CRV_EL', 2025, 'LS', 'TLOW08',   '2025-12-20', '2025-12-10', 2, 'Lost to Carvana online purchase.'),
((SELECT customer_id FROM customer WHERE email='jpeacock@email.com'),    'DLR08', 'ADV', 'CIVICX', 2025, 'CT', 'KSANT08',  '2026-02-15', '2026-02-05', 1, 'No response to 3 follow-up calls.'),
((SELECT customer_id FROM customer WHERE email='ralcantar@email.com'),   'DLR08', 'REF', 'PILTEX', 2025, 'DD', 'TLOW08',   '2025-11-25', '2025-11-20', 2, 'Decided against purchase. Dead lead.'),
((SELECT customer_id FROM customer WHERE email='cshoemaker@email.com'),  'DLR08', 'RPT', 'CRV_EL', 2025, 'CT', 'KSANT08',  '2026-03-10', '2026-02-20', 1, 'Stale — needs re-engagement.'),
((SELECT customer_id FROM customer WHERE email='jwhitfield08@email.com'),'DLR08', 'WEB', 'ACCORD', 2026, 'NW', 'TLOW08',   '2026-04-16', NULL,         0, 'Fresh online inquiry.'),
-- DLR09 leads (warranty hotspot — normal volume)
((SELECT customer_id FROM customer WHERE email='gthibodaux@email.com'),  'DLR09', 'WLK', 'SILVLT', 2025, 'WN', 'MJOHN09',  '2025-12-22', '2025-12-20', 3, 'Purchased Silverado.'),
((SELECT customer_id FROM customer WHERE email='mspellman@email.com'),   'DLR09', 'WEB', 'EQNOLT', 2026, 'WN', 'BFOSTER9', '2026-01-26', '2026-01-22', 2, 'Purchased Equinox LT.'),
((SELECT customer_id FROM customer WHERE email='cpendergrass@email.com'),'DLR09', 'RPT', 'SILVLT', 2025, 'WN', 'MJOHN09',  '2026-03-02', '2026-02-28', 4, 'Fleet buyer closed 3 trucks.'),
((SELECT customer_id FROM customer WHERE email='wambrose@email.com'),    'DLR09', 'REF', 'EQNOLT', 2026, 'PR', 'BFOSTER9', '2026-04-18', '2026-04-10', 2, 'Negotiating EV Equinox.'),
((SELECT customer_id FROM customer WHERE email='dodom@email.com'),       'DLR09', 'WEB', 'MALIBU', 2025, 'QF', 'MJOHN09',  '2026-04-23', '2026-04-15', 2, 'Qualified, wants Malibu.'),
((SELECT customer_id FROM customer WHERE email='lwashburn@email.com'),   'DLR09', 'ADV', 'SILVLT', 2025, 'CT', 'BFOSTER9', '2026-04-20', '2026-04-14', 1, 'Initial inquiry on Silverado.'),
-- DLR10 leads (F&I powerhouse — high conversion)
((SELECT customer_id FROM customer WHERE email='tbancroft@email.com'),   'DLR10', 'WEB', 'CAMRYL', 2025, 'WN', 'SMART10',  '2026-01-12', '2026-01-10', 3, 'Purchased Camry with extended VSC.'),
((SELECT customer_id FROM customer WHERE email='mengstrom@email.com'),   'DLR10', 'REF', 'RAV4XP', 2025, 'WN', 'EYOUNG10', '2026-02-24', '2026-02-22', 4, 'Purchased RAV4 with GAP + VSC bundle.'),
((SELECT customer_id FROM customer WHERE email='bkirkpatrick@email.com'),'DLR10', 'RPT', 'HGHLXL', 2025, 'WN', 'SMART10',  '2026-01-27', '2026-01-25', 3, 'Purchased Highlander, full F&I.'),
((SELECT customer_id FROM customer WHERE email='aredmond@email.com'),    'DLR10', 'WLK', 'TACSR5', 2025, 'WN', 'EYOUNG10', '2026-03-26', '2026-03-24', 3, 'Purchased Tacoma with tire/wheel.'),
((SELECT customer_id FROM customer WHERE email='cfairchild@email.com'),  'DLR10', 'WEB', 'HGHLXL', 2025, 'PR', 'SMART10',  '2026-04-22', '2026-04-16', 2, 'Negotiating Highlander Platinum.'),
-- DLR11 leads (baseline)
((SELECT customer_id FROM customer WHERE email='hvanderberg@email.com'), 'DLR11', 'WLK', 'F150XL', 2025, 'WN', 'JWOOD11',  '2026-02-26', '2026-02-22', 3, 'Purchased F-150 XLT.'),
((SELECT customer_id FROM customer WHERE email='bsorensen@email.com'),   'DLR11', 'WEB', 'ESCSEL', 2025, 'WN', 'HKNIGH1',  '2025-12-20', '2025-12-15', 3, 'Purchased Escape.'),
((SELECT customer_id FROM customer WHERE email='rbouchard@email.com'),   'DLR11', 'REF', 'EXPLLT', 2026, 'PR', 'JWOOD11',  '2026-04-20', '2026-04-14', 2, 'Evaluating Explorer.'),
((SELECT customer_id FROM customer WHERE email='carellano@email.com'),   'DLR11', 'ADV', 'ESCSEL', 2025, 'QF', 'HKNIGH1',  '2026-04-21', '2026-04-15', 2, 'Qualified, needs test drive.'),
((SELECT customer_id FROM customer WHERE email='hunderwood@email.com'),  'DLR11', 'RPT', 'F150XL', 2026, 'CT', 'JWOOD11',  '2026-04-24', '2026-04-16', 1, 'Repeat customer, initial contact.'),
-- DLR12 leads (baseline)
((SELECT customer_id FROM customer WHERE email='dmcnamara@email.com'),   'DLR12', 'WLK', 'CRV_EL', 2025, 'WN', 'GLOPE12',  '2026-02-06', '2026-02-02', 3, 'Purchased CR-V EX-L.'),
((SELECT customer_id FROM customer WHERE email='abrockway@email.com'),   'DLR12', 'WEB', 'CIVICX', 2025, 'WN', 'OWARD12',  '2026-01-02', '2025-12-28', 3, 'Purchased Civic EX.'),
((SELECT customer_id FROM customer WHERE email='ksumner@email.com'),     'DLR12', 'REF', 'PILTEX', 2025, 'WN', 'GLOPE12',  '2026-04-10', '2026-04-06', 3, 'Purchased Pilot EX-L.'),
((SELECT customer_id FROM customer WHERE email='pyeager@email.com'),     'DLR12', 'ADV', 'ACCORD', 2026, 'QF', 'OWARD12',  '2026-04-21', '2026-04-14', 2, 'Qualified, negotiating Accord.'),
((SELECT customer_id FROM customer WHERE email='sgreenlee@email.com'),   'DLR12', 'RPT', 'PILTEX', 2025, 'PR', 'GLOPE12',  '2026-04-19', '2026-04-13', 2, 'Repeat customer, Pilot negotiation.');
