-- V5__create_production_logistics_tables.sql
-- Creates production and logistics tables: production_order, shipment,
-- shipment_vehicle, transit_status, and pdi_schedule.
-- Translated from DB2 DDL to PostgreSQL for the AUTOSALES modernization.

CREATE TABLE production_order (
    production_id    VARCHAR(12)    NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    plant_code       VARCHAR(4)     NOT NULL,
    build_date       DATE,
    build_status     VARCHAR(2)     NOT NULL DEFAULT 'SC',
    allocated_dealer VARCHAR(5),
    allocation_date  DATE,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (production_id)
);

CREATE TABLE shipment (
    shipment_id      VARCHAR(12)    NOT NULL,
    carrier_code     VARCHAR(5)     NOT NULL,
    carrier_name     VARCHAR(40),
    origin_plant     VARCHAR(4)     NOT NULL,
    dest_dealer      VARCHAR(5)     NOT NULL,
    transport_mode   VARCHAR(2)     NOT NULL,
    vehicle_count    SMALLINT       NOT NULL DEFAULT 0,
    ship_date        DATE,
    est_arrival_date DATE,
    act_arrival_date DATE,
    shipment_status  VARCHAR(2)     NOT NULL DEFAULT 'CR',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (shipment_id)
);

CREATE TABLE shipment_vehicle (
    shipment_id      VARCHAR(12)    NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    load_sequence    SMALLINT       NOT NULL,
    PRIMARY KEY (shipment_id, vin),
    FOREIGN KEY (shipment_id) REFERENCES shipment (shipment_id)
);

CREATE TABLE transit_status (
    vin              VARCHAR(17)    NOT NULL,
    status_seq       INTEGER        NOT NULL,
    location_desc    VARCHAR(60)    NOT NULL,
    status_code      VARCHAR(2)     NOT NULL,
    edi_ref_num      VARCHAR(20),
    status_ts        TIMESTAMP      NOT NULL,
    received_ts      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (vin, status_seq)
);

CREATE TABLE pdi_schedule (
    pdi_id           INTEGER        GENERATED ALWAYS AS IDENTITY,
    vin              VARCHAR(17)    NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    scheduled_date   DATE           NOT NULL,
    technician_id    VARCHAR(8),
    pdi_status       VARCHAR(2)     NOT NULL DEFAULT 'SC',
    checklist_items  SMALLINT       NOT NULL DEFAULT 25,
    items_passed     SMALLINT       NOT NULL DEFAULT 0,
    items_failed     SMALLINT       NOT NULL DEFAULT 0,
    notes            VARCHAR(200),
    completed_ts     TIMESTAMP,
    PRIMARY KEY (pdi_id)
);
