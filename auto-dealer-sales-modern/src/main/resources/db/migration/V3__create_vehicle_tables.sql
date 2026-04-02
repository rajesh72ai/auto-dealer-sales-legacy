-- V3__create_vehicle_tables.sql
-- Creates vehicle inventory tables: vehicle, vehicle_option,
-- vehicle_status_hist, and lot_location.
-- Translated from DB2 DDL to PostgreSQL for the AUTOSALES modernization.

CREATE TABLE vehicle (
    vin              VARCHAR(17)    NOT NULL,
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    exterior_color   VARCHAR(3)     NOT NULL,
    interior_color   VARCHAR(3)     NOT NULL,
    engine_num       VARCHAR(20),
    production_date  DATE,
    ship_date        DATE,
    receive_date     DATE,
    vehicle_status   VARCHAR(2)     NOT NULL DEFAULT 'PR',
    dealer_code      VARCHAR(5),
    lot_location     VARCHAR(6),
    stock_number     VARCHAR(8),
    days_in_stock    SMALLINT       NOT NULL DEFAULT 0,
    pdi_complete     VARCHAR(1)     NOT NULL DEFAULT 'N',
    pdi_date         DATE,
    damage_flag      VARCHAR(1)     NOT NULL DEFAULT 'N',
    damage_desc      VARCHAR(200),
    odometer         INTEGER        NOT NULL DEFAULT 0,
    key_number       VARCHAR(6),
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (vin),
    FOREIGN KEY (model_year, make_code, model_code) REFERENCES model_master (model_year, make_code, model_code)
);

CREATE TABLE vehicle_option (
    vin              VARCHAR(17)    NOT NULL,
    option_code      VARCHAR(6)     NOT NULL,
    option_desc      VARCHAR(40)    NOT NULL,
    option_price     NUMERIC(9,2)   NOT NULL DEFAULT 0,
    installed_flag   VARCHAR(1)     NOT NULL DEFAULT 'F',
    PRIMARY KEY (vin, option_code),
    FOREIGN KEY (vin) REFERENCES vehicle (vin)
);

CREATE TABLE vehicle_status_hist (
    vin              VARCHAR(17)    NOT NULL,
    status_seq       INTEGER        NOT NULL,
    old_status       VARCHAR(2)     NOT NULL,
    new_status       VARCHAR(2)     NOT NULL,
    changed_by       VARCHAR(8)     NOT NULL,
    change_reason    VARCHAR(60),
    changed_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (vin, status_seq),
    FOREIGN KEY (vin) REFERENCES vehicle (vin)
);

CREATE TABLE lot_location (
    dealer_code      VARCHAR(5)     NOT NULL,
    location_code    VARCHAR(6)     NOT NULL,
    location_desc    VARCHAR(30)    NOT NULL,
    location_type    VARCHAR(1)     NOT NULL,
    max_capacity     SMALLINT       NOT NULL DEFAULT 0,
    current_count    SMALLINT       NOT NULL DEFAULT 0,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    PRIMARY KEY (dealer_code, location_code),
    FOREIGN KEY (dealer_code) REFERENCES dealer (dealer_code)
);
