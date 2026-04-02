-- V2__create_pricing_reference_tables.sql
-- Creates pricing and reference tables: price_master, incentive_program,
-- tax_rate, and price_schedule.
-- Translated from DB2 DDL to PostgreSQL for the AUTOSALES modernization.

CREATE TABLE price_master (
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    msrp             NUMERIC(11,2)  NOT NULL,
    invoice_price    NUMERIC(11,2)  NOT NULL,
    holdback_amt     NUMERIC(9,2)   NOT NULL DEFAULT 0,
    holdback_pct     NUMERIC(5,3)   NOT NULL DEFAULT 0,
    destination_fee  NUMERIC(7,2)   NOT NULL DEFAULT 0,
    advertising_fee  NUMERIC(7,2)   NOT NULL DEFAULT 0,
    effective_date   DATE           NOT NULL,
    expiry_date      DATE,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (model_year, make_code, model_code, effective_date),
    FOREIGN KEY (model_year, make_code, model_code) REFERENCES model_master (model_year, make_code, model_code)
);

CREATE TABLE incentive_program (
    incentive_id     VARCHAR(10)    NOT NULL,
    incentive_name   VARCHAR(60)    NOT NULL,
    incentive_type   VARCHAR(2)     NOT NULL,
    model_year       SMALLINT,
    make_code        VARCHAR(3),
    model_code       VARCHAR(6),
    region_code      VARCHAR(3),
    amount           NUMERIC(9,2)   NOT NULL DEFAULT 0,
    rate_override    NUMERIC(5,3),
    start_date       DATE           NOT NULL,
    end_date         DATE           NOT NULL,
    max_units        INTEGER,
    units_used       INTEGER        NOT NULL DEFAULT 0,
    stackable_flag   VARCHAR(1)     NOT NULL DEFAULT 'N',
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (incentive_id)
);

CREATE TABLE tax_rate (
    state_code       VARCHAR(2)     NOT NULL,
    county_code      VARCHAR(5)     NOT NULL,
    city_code        VARCHAR(5)     NOT NULL DEFAULT '00000',
    state_rate       NUMERIC(5,4)   NOT NULL,
    county_rate      NUMERIC(5,4)   NOT NULL DEFAULT 0,
    city_rate        NUMERIC(5,4)   NOT NULL DEFAULT 0,
    doc_fee_max      NUMERIC(7,2)   NOT NULL DEFAULT 0,
    title_fee        NUMERIC(7,2)   NOT NULL DEFAULT 0,
    reg_fee          NUMERIC(7,2)   NOT NULL DEFAULT 0,
    effective_date   DATE           NOT NULL,
    expiry_date      DATE,
    PRIMARY KEY (state_code, county_code, city_code, effective_date)
);

CREATE TABLE price_schedule (
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    schedule_type    VARCHAR(2)     NOT NULL,
    msrp             NUMERIC(11,2)  NOT NULL DEFAULT 0,
    invoice_price    NUMERIC(11,2)  NOT NULL DEFAULT 0,
    dealer_price     NUMERIC(11,2)  NOT NULL DEFAULT 0,
    holdback_amt     NUMERIC(9,2)   NOT NULL DEFAULT 0,
    destination_fee  NUMERIC(7,2)   NOT NULL DEFAULT 0,
    effective_date   DATE           NOT NULL,
    expiry_date      DATE,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (model_year, make_code, model_code, schedule_type, effective_date),
    FOREIGN KEY (model_year, make_code, model_code) REFERENCES model_master (model_year, make_code, model_code)
);
