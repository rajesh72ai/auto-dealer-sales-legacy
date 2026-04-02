-- V4__create_stock_tables.sql
-- Creates stock management tables: stock_position, stock_snapshot,
-- stock_adjustment, and stock_transfer.
-- Translated from DB2 DDL to PostgreSQL for the AUTOSALES modernization.

CREATE TABLE stock_position (
    dealer_code      VARCHAR(5)     NOT NULL,
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    on_hand_count    SMALLINT       NOT NULL DEFAULT 0,
    in_transit_count SMALLINT       NOT NULL DEFAULT 0,
    allocated_count  SMALLINT       NOT NULL DEFAULT 0,
    on_hold_count    SMALLINT       NOT NULL DEFAULT 0,
    sold_mtd         SMALLINT       NOT NULL DEFAULT 0,
    sold_ytd         SMALLINT       NOT NULL DEFAULT 0,
    reorder_point    SMALLINT       NOT NULL DEFAULT 5,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (dealer_code, model_year, make_code, model_code)
);

CREATE TABLE stock_snapshot (
    snapshot_date    DATE           NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    on_hand_count    SMALLINT       NOT NULL DEFAULT 0,
    in_transit_count SMALLINT       NOT NULL DEFAULT 0,
    on_hold_count    SMALLINT       NOT NULL DEFAULT 0,
    total_value      NUMERIC(13,2)  NOT NULL DEFAULT 0,
    avg_days_in_stock SMALLINT      NOT NULL DEFAULT 0,
    PRIMARY KEY (snapshot_date, dealer_code, model_year, make_code, model_code)
);

CREATE TABLE stock_adjustment (
    adjust_id        INTEGER        GENERATED ALWAYS AS IDENTITY,
    dealer_code      VARCHAR(5)     NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    adjust_type      VARCHAR(2)     NOT NULL,
    adjust_reason    VARCHAR(100)   NOT NULL,
    old_status       VARCHAR(2)     NOT NULL,
    new_status       VARCHAR(2)     NOT NULL,
    adjusted_by      VARCHAR(8)     NOT NULL,
    adjusted_ts      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (adjust_id)
);

CREATE TABLE stock_transfer (
    transfer_id      INTEGER        GENERATED ALWAYS AS IDENTITY,
    from_dealer      VARCHAR(5)     NOT NULL,
    to_dealer        VARCHAR(5)     NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    transfer_status  VARCHAR(2)     NOT NULL DEFAULT 'RQ',
    requested_by     VARCHAR(8)     NOT NULL,
    approved_by      VARCHAR(8),
    requested_ts     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_ts      TIMESTAMP,
    completed_ts     TIMESTAMP,
    PRIMARY KEY (transfer_id)
);
