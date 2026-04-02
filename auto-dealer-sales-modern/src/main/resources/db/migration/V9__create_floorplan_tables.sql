-- V9: Floor plan domain tables
-- Tables: floor_plan_lender, floor_plan_vehicle, floor_plan_interest

CREATE TABLE floor_plan_lender (
    lender_id        VARCHAR(5)     NOT NULL,
    lender_name      VARCHAR(40)    NOT NULL,
    contact_name     VARCHAR(40),
    phone            VARCHAR(10),
    base_rate        NUMERIC(5,3)   NOT NULL,
    spread           NUMERIC(5,3)   NOT NULL,
    curtailment_days INTEGER        NOT NULL DEFAULT 90,
    free_floor_days  INTEGER        NOT NULL DEFAULT 0,
    PRIMARY KEY (lender_id)
);

CREATE TABLE floor_plan_vehicle (
    floor_plan_id    INTEGER        GENERATED ALWAYS AS IDENTITY,
    vin              VARCHAR(17)    NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    lender_id        VARCHAR(5)     NOT NULL,
    invoice_amount   NUMERIC(11,2)  NOT NULL,
    current_balance  NUMERIC(11,2)  NOT NULL,
    interest_accrued NUMERIC(9,2)   NOT NULL DEFAULT 0,
    floor_date       DATE           NOT NULL,
    curtailment_date DATE,
    payoff_date      DATE,
    fp_status        VARCHAR(2)     NOT NULL DEFAULT 'AC',
    days_on_floor    SMALLINT       NOT NULL DEFAULT 0,
    last_interest_dt DATE,
    PRIMARY KEY (floor_plan_id),
    FOREIGN KEY (vin) REFERENCES vehicle (vin),
    FOREIGN KEY (lender_id) REFERENCES floor_plan_lender (lender_id)
);

CREATE TABLE floor_plan_interest (
    interest_id      INTEGER        GENERATED ALWAYS AS IDENTITY,
    floor_plan_id    INTEGER        NOT NULL,
    calc_date        DATE           NOT NULL,
    principal_bal    NUMERIC(11,2)  NOT NULL,
    rate_applied     NUMERIC(5,3)   NOT NULL,
    daily_interest   NUMERIC(9,4)   NOT NULL,
    cumulative_int   NUMERIC(9,2)   NOT NULL,
    PRIMARY KEY (interest_id),
    FOREIGN KEY (floor_plan_id) REFERENCES floor_plan_vehicle (floor_plan_id)
);
