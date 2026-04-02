-- V1__create_admin_tables.sql
-- Creates core administrative tables: system_user, dealer, model_master,
-- system_config, salesperson, and lender.
-- Translated from DB2 DDL to PostgreSQL for the AUTOSALES modernization.

CREATE TABLE "system_user" (
    user_id          VARCHAR(8)     NOT NULL,
    user_name        VARCHAR(40)    NOT NULL,
    password_hash    VARCHAR(64)    NOT NULL,
    user_type        VARCHAR(1)     NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    last_login_ts    TIMESTAMP,
    failed_attempts  INTEGER        NOT NULL DEFAULT 0,
    locked_flag      VARCHAR(1)     NOT NULL DEFAULT 'N',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id)
);

CREATE TABLE dealer (
    dealer_code      VARCHAR(5)     NOT NULL,
    dealer_name      VARCHAR(60)    NOT NULL,
    address_line1    VARCHAR(50)    NOT NULL,
    address_line2    VARCHAR(50),
    city             VARCHAR(30)    NOT NULL,
    state_code       VARCHAR(2)     NOT NULL,
    zip_code         VARCHAR(10)    NOT NULL,
    phone_number     VARCHAR(10)    NOT NULL,
    fax_number       VARCHAR(10),
    dealer_principal VARCHAR(40)    NOT NULL,
    region_code      VARCHAR(3)     NOT NULL,
    zone_code        VARCHAR(2)     NOT NULL,
    oem_dealer_num   VARCHAR(10)    NOT NULL,
    floor_plan_lender_id VARCHAR(5),
    max_inventory    SMALLINT       NOT NULL DEFAULT 500,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    opened_date      DATE           NOT NULL,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (dealer_code)
);

CREATE TABLE model_master (
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    model_name       VARCHAR(40)    NOT NULL,
    body_style       VARCHAR(2)     NOT NULL,
    trim_level       VARCHAR(3)     NOT NULL,
    engine_type      VARCHAR(3)     NOT NULL,
    transmission     VARCHAR(1)     NOT NULL,
    drive_train      VARCHAR(3)     NOT NULL,
    exterior_colors  VARCHAR(200),
    interior_colors  VARCHAR(200),
    curb_weight      INTEGER,
    fuel_economy_city   SMALLINT,
    fuel_economy_hwy    SMALLINT,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (model_year, make_code, model_code)
);

CREATE TABLE system_config (
    config_key       VARCHAR(30)    NOT NULL,
    config_value     VARCHAR(100)   NOT NULL,
    config_desc      VARCHAR(60),
    updated_by       VARCHAR(8),
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (config_key)
);

CREATE TABLE salesperson (
    salesperson_id   VARCHAR(8)     NOT NULL,
    salesperson_name VARCHAR(30)    NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    hire_date        DATE,
    termination_date DATE,
    commission_plan  VARCHAR(2)     NOT NULL DEFAULT 'ST',
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (salesperson_id),
    FOREIGN KEY (dealer_code) REFERENCES dealer (dealer_code)
);

CREATE TABLE lender (
    lender_id        VARCHAR(5)     NOT NULL,
    lender_name      VARCHAR(40)    NOT NULL,
    contact_name     VARCHAR(40),
    phone            VARCHAR(10),
    address_line1    VARCHAR(50),
    city             VARCHAR(30),
    state_code       VARCHAR(2),
    zip_code         VARCHAR(10),
    lender_type      VARCHAR(2)     NOT NULL DEFAULT 'FP',
    base_rate        NUMERIC(5,3)   NOT NULL DEFAULT 0,
    spread           NUMERIC(5,3)   NOT NULL DEFAULT 0,
    curtailment_days INTEGER        NOT NULL DEFAULT 90,
    free_floor_days  INTEGER        NOT NULL DEFAULT 0,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (lender_id)
);
