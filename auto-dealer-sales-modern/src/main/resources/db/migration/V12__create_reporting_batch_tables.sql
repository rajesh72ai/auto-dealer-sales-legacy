-- V12: Reporting and batch processing tables
-- Tables: daily_sales_summary, monthly_snapshot, commission, commission_audit,
--         restart_control, audit_log, batch_control, batch_checkpoint

CREATE TABLE daily_sales_summary (
    summary_date     DATE           NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    model_year       SMALLINT       NOT NULL,
    make_code        VARCHAR(3)     NOT NULL,
    model_code       VARCHAR(6)     NOT NULL,
    units_sold       SMALLINT       NOT NULL DEFAULT 0,
    total_revenue    NUMERIC(13,2)  NOT NULL DEFAULT 0,
    total_gross      NUMERIC(11,2)  NOT NULL DEFAULT 0,
    front_gross      NUMERIC(11,2)  NOT NULL DEFAULT 0,
    back_gross       NUMERIC(11,2)  NOT NULL DEFAULT 0,
    avg_selling_price NUMERIC(11,2) NOT NULL DEFAULT 0,
    avg_gross_per_unit NUMERIC(9,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (summary_date, dealer_code, model_year, make_code, model_code)
);

CREATE TABLE monthly_snapshot (
    snapshot_month   VARCHAR(6)     NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    total_units_sold SMALLINT       NOT NULL DEFAULT 0,
    total_revenue    NUMERIC(15,2)  NOT NULL DEFAULT 0,
    total_gross      NUMERIC(13,2)  NOT NULL DEFAULT 0,
    total_fi_gross   NUMERIC(11,2)  NOT NULL DEFAULT 0,
    avg_days_to_sell SMALLINT       NOT NULL DEFAULT 0,
    inventory_turn   NUMERIC(5,2)   NOT NULL DEFAULT 0,
    fi_per_deal      NUMERIC(9,2)   NOT NULL DEFAULT 0,
    csi_score        NUMERIC(5,2),
    frozen_flag      VARCHAR(1)     NOT NULL DEFAULT 'N',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (snapshot_month, dealer_code)
);

CREATE TABLE commission (
    commission_id    INTEGER        GENERATED ALWAYS AS IDENTITY,
    dealer_code      VARCHAR(5)     NOT NULL,
    salesperson_id   VARCHAR(8)     NOT NULL,
    deal_number      VARCHAR(10)    NOT NULL,
    comm_type        VARCHAR(2)     NOT NULL,
    gross_amount     NUMERIC(11,2)  NOT NULL,
    comm_rate        NUMERIC(5,4)   NOT NULL,
    comm_amount      NUMERIC(9,2)   NOT NULL,
    pay_period       VARCHAR(6)     NOT NULL,
    paid_flag        VARCHAR(1)     NOT NULL DEFAULT 'N',
    calc_ts          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (commission_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);

CREATE TABLE commission_audit (
    audit_id         INTEGER        GENERATED ALWAYS AS IDENTITY,
    deal_number      VARCHAR(10)    NOT NULL,
    entity_type      VARCHAR(8)     NOT NULL,
    description      VARCHAR(200)   NOT NULL,
    audit_ts         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (audit_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);

CREATE TABLE restart_control (
    job_name         VARCHAR(8)     NOT NULL,
    step_name        VARCHAR(8)     NOT NULL,
    checkpoint_id    VARCHAR(20)    NOT NULL,
    records_processed INTEGER       NOT NULL DEFAULT 0,
    last_key_value   VARCHAR(50),
    restart_flag     VARCHAR(1)     NOT NULL DEFAULT 'N',
    status           VARCHAR(1)     NOT NULL DEFAULT 'C',
    started_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checkpoint_ts    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_ts     TIMESTAMP,
    PRIMARY KEY (job_name, step_name)
);

CREATE TABLE audit_log (
    audit_id         INTEGER        GENERATED ALWAYS AS IDENTITY,
    user_id          VARCHAR(8)     NOT NULL,
    program_id       VARCHAR(8)     NOT NULL,
    action_type      VARCHAR(3)     NOT NULL,
    table_name       VARCHAR(30),
    key_value        VARCHAR(50),
    old_value        VARCHAR(200),
    new_value        VARCHAR(200),
    audit_ts         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (audit_id)
);

CREATE TABLE batch_control (
    program_id       VARCHAR(8)     NOT NULL,
    last_run_date    DATE,
    last_sync_date   DATE,
    records_processed INTEGER       NOT NULL DEFAULT 0,
    run_status       VARCHAR(2)     NOT NULL DEFAULT 'CP',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (program_id)
);

CREATE TABLE batch_checkpoint (
    program_id       VARCHAR(8)     NOT NULL,
    checkpoint_seq   INTEGER        NOT NULL,
    checkpoint_timestamp TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_key_value   VARCHAR(30),
    records_in       INTEGER        NOT NULL DEFAULT 0,
    records_out      INTEGER        NOT NULL DEFAULT 0,
    records_error    INTEGER        NOT NULL DEFAULT 0,
    checkpoint_status VARCHAR(2)    NOT NULL DEFAULT 'AC',
    PRIMARY KEY (program_id, checkpoint_seq)
);
