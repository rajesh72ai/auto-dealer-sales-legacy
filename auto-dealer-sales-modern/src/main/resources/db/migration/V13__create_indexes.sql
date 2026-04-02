-- ==========================================================
-- AUTOSALES - Non-Primary Key Indexes
-- ==========================================================

-- Vehicle indexes
CREATE INDEX ix_veh_dealer ON vehicle (dealer_code, vehicle_status);
CREATE INDEX ix_veh_model ON vehicle (model_year, make_code, model_code);
CREATE INDEX ix_veh_stock ON vehicle (stock_number);

-- Production indexes
CREATE INDEX ix_prod_vin ON production_order (vin);

-- Customer indexes
CREATE INDEX ix_cust_name ON customer (last_name, first_name);
CREATE INDEX ix_cust_phone ON customer (cell_phone);
CREATE INDEX ix_cust_dlr ON customer (dealer_code);

-- Sales Deal indexes
CREATE INDEX ix_deal_dlr ON sales_deal (dealer_code, deal_date);
CREATE INDEX ix_deal_vin ON sales_deal (vin);

-- Floor Plan indexes
CREATE INDEX ix_fp_vin ON floor_plan_vehicle (vin);
CREATE INDEX ix_fp_dealer ON floor_plan_vehicle (dealer_code, fp_status);

-- Audit indexes
CREATE INDEX ix_audit_user ON audit_log (user_id, audit_ts);
CREATE INDEX ix_audit_pgm ON audit_log (program_id, audit_ts);

-- Salesperson indexes
CREATE INDEX ix_sp_dealer ON salesperson (dealer_code, active_flag);

-- Commission audit indexes
CREATE INDEX ix_comm_audit_deal ON commission_audit (deal_number);

-- Warranty claim indexes
CREATE INDEX ix_wc_dealer ON warranty_claim (dealer_code, claim_status);
CREATE INDEX ix_wc_vin ON warranty_claim (vin);
CREATE INDEX ix_wc_date ON warranty_claim (claim_date);
