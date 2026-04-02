-- ==========================================================================
-- V15: Seed data - dealers, users, lot locations, tax rates, system config
-- Source: Legacy IMS DC/COBOL/DB2 AUTOSALES system
-- ==========================================================================

-- Floor Plan Lenders
INSERT INTO floor_plan_lender (lender_id, lender_name, contact_name, phone, base_rate, spread, curtailment_days, free_floor_days) VALUES ('ALLY1', 'Ally Financial Auto', 'Karen Mitchell', '8005551000', 5.500, 1.250, 90, 3);
INSERT INTO floor_plan_lender (lender_id, lender_name, contact_name, phone, base_rate, spread, curtailment_days, free_floor_days) VALUES ('CHASE', 'Chase Auto Dealer Svcs', 'David Park', '8005552000', 5.750, 1.000, 90, 5);
INSERT INTO floor_plan_lender (lender_id, lender_name, contact_name, phone, base_rate, spread, curtailment_days, free_floor_days) VALUES ('BMWFS', 'BMW Financial Services', 'Lisa Braun', '8005553000', 4.250, 0.750, 120, 7);

-- Dealers
INSERT INTO dealer (dealer_code, dealer_name, address_line1, city, state_code, zip_code, phone_number, fax_number, dealer_principal, region_code, zone_code, oem_dealer_num, floor_plan_lender_id, max_inventory, active_flag, opened_date) VALUES ('DLR01', 'Lakewood Ford', '4500 W Colfax Ave', 'Lakewood', 'CO', '80401', '3035551234', '3035551235', 'James Patterson', 'MTN', 'W1', 'FRD0044501', 'ALLY1', 400, 'Y', '2005-06-15');
INSERT INTO dealer (dealer_code, dealer_name, address_line1, city, state_code, zip_code, phone_number, fax_number, dealer_principal, region_code, zone_code, oem_dealer_num, floor_plan_lender_id, max_inventory, active_flag, opened_date) VALUES ('DLR02', 'Northside Toyota', '8200 N Michigan Rd', 'Indianapolis', 'IN', '46268', '3175552345', '3175552346', 'Maria Santos', 'GLK', 'E2', 'TYT0082001', 'ALLY1', 500, 'Y', '2001-03-22');
INSERT INTO dealer (dealer_code, dealer_name, address_line1, city, state_code, zip_code, phone_number, fax_number, dealer_principal, region_code, zone_code, oem_dealer_num, floor_plan_lender_id, max_inventory, active_flag, opened_date) VALUES ('DLR03', 'Valley Honda of Chandler', '1250 S Arizona Ave', 'Chandler', 'AZ', '85286', '4805553456', '4805553457', 'Robert Nguyen', 'SWS', 'W3', 'HND0012501', 'CHASE', 350, 'Y', '2010-09-01');
INSERT INTO dealer (dealer_code, dealer_name, address_line1, city, state_code, zip_code, phone_number, fax_number, dealer_principal, region_code, zone_code, oem_dealer_num, floor_plan_lender_id, max_inventory, active_flag, opened_date) VALUES ('DLR04', 'Peachtree Chevrolet', '3300 Peachtree Rd NE', 'Atlanta', 'GA', '30326', '4045554567', '4045554568', 'William Clark', 'SES', 'E4', 'CHV0033001', 'CHASE', 450, 'Y', '1998-11-10');
INSERT INTO dealer (dealer_code, dealer_name, address_line1, city, state_code, zip_code, phone_number, fax_number, dealer_principal, region_code, zone_code, oem_dealer_num, floor_plan_lender_id, max_inventory, active_flag, opened_date) VALUES ('DLR05', 'Prestige BMW of Westport', '900 Post Rd East', 'Westport', 'CT', '06880', '2035555678', '2035555679', 'Elizabeth Hartmann', 'NES', 'E1', 'BMW0009001', 'BMWFS', 200, 'Y', '2012-04-18');

-- Lot Locations (3 per dealer)
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR01', 'SHOW01', 'Main Showroom', 'S', 12, 5);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR01', 'FRNT01', 'Front Display Lot', 'F', 80, 32);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR01', 'BACK01', 'Rear Overflow Lot', 'B', 200, 45);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR02', 'SHOW01', 'Showroom Floor', 'S', 15, 7);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR02', 'FRNT01', 'Front Lot', 'F', 100, 48);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR02', 'OFFST1', 'Offsite Storage', 'O', 150, 30);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR03', 'SHOW01', 'Main Showroom', 'S', 10, 4);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR03', 'FRNT01', 'Front Lot A', 'F', 70, 28);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR03', 'RECON1', 'Reconditioning Bay', 'R', 8, 3);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR04', 'SHOW01', 'Showroom', 'S', 14, 6);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR04', 'FRNT01', 'Front Display', 'F', 90, 40);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR04', 'BACK01', 'Back Lot', 'B', 180, 55);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR05', 'SHOW01', 'Luxury Showroom', 'S', 8, 4);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR05', 'FRNT01', 'Front Display', 'F', 50, 22);
INSERT INTO lot_location (dealer_code, location_code, location_desc, location_type, max_capacity, current_count) VALUES ('DLR05', 'BACK01', 'Covered Storage', 'B', 60, 18);

-- System Users with BCrypt password hash (password: password123)
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('SYSADMIN', 'System Administrator', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'A', 'DLR01', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('JPATTER1', 'James Patterson', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR01', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('TSMITH01', 'Tom Smith', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR01', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('MSANTOS1', 'Maria Santos', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR02', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('DJONES02', 'Diana Jones', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR02', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('RNGUYEN3', 'Robert Nguyen', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR03', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('KLEE0003', 'Kevin Lee', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR03', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('FIMGR03', 'Angela Torres', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'F', 'DLR03', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('WCLARK04', 'William Clark', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR04', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('MBROWN04', 'Mike Brown', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR04', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('EHART005', 'Elizabeth Hartmann', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'M', 'DLR05', 'Y');
INSERT INTO "system_user" (user_id, user_name, password_hash, user_type, dealer_code, active_flag) VALUES ('PCHEN005', 'Peter Chen', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'S', 'DLR05', 'Y');

-- Tax Rates
INSERT INTO tax_rate (state_code, county_code, city_code, state_rate, county_rate, city_rate, doc_fee_max, title_fee, reg_fee, effective_date) VALUES ('CO', '00001', '00000', 0.0290, 0.0100, 0.0375, 799.00, 7.20, 50.00, '2025-01-01');
INSERT INTO tax_rate (state_code, county_code, city_code, state_rate, county_rate, city_rate, doc_fee_max, title_fee, reg_fee, effective_date) VALUES ('IN', '00001', '00000', 0.0700, 0.0000, 0.0000, 199.00, 15.00, 21.35, '2025-01-01');
INSERT INTO tax_rate (state_code, county_code, city_code, state_rate, county_rate, city_rate, doc_fee_max, title_fee, reg_fee, effective_date) VALUES ('AZ', '00001', '00000', 0.0560, 0.0070, 0.0180, 599.00, 4.00, 32.00, '2025-01-01');
INSERT INTO tax_rate (state_code, county_code, city_code, state_rate, county_rate, city_rate, doc_fee_max, title_fee, reg_fee, effective_date) VALUES ('GA', '00001', '00000', 0.0400, 0.0300, 0.0150, 699.00, 18.00, 20.00, '2025-01-01');
INSERT INTO tax_rate (state_code, county_code, city_code, state_rate, county_rate, city_rate, doc_fee_max, title_fee, reg_fee, effective_date) VALUES ('CT', '00001', '00000', 0.0635, 0.0000, 0.0000, 599.00, 25.00, 120.00, '2025-01-01');

-- System Config
INSERT INTO system_config (config_key, config_value, config_desc, updated_by) VALUES ('NEXT_DEAL_NUMBER', '0000000026', 'Next deal sequence number', 'SYSADMIN');
INSERT INTO system_config (config_key, config_value, config_desc, updated_by) VALUES ('NEXT_FINANCE_ID', '000000000016', 'Next finance app ID', 'SYSADMIN');
INSERT INTO system_config (config_key, config_value, config_desc, updated_by) VALUES ('NEXT_REG_ID', '000000000016', 'Next registration ID', 'SYSADMIN');
INSERT INTO system_config (config_key, config_value, config_desc, updated_by) VALUES ('BATCH_COMMIT_FREQ', '500', 'Commit frequency for batch', 'SYSADMIN');
INSERT INTO system_config (config_key, config_value, config_desc, updated_by) VALUES ('MAX_CREDIT_AGE_DAYS', '30', 'Credit report expiry days', 'SYSADMIN');
INSERT INTO system_config (config_key, config_value, config_desc, updated_by) VALUES ('FLOOR_PLAN_RATE_DATE', '2025-01-15', 'Rate effective date', 'SYSADMIN');
