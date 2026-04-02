-- V8: Finance domain tables
-- Tables: finance_app, finance_product, lease_terms, fi_deal_product

CREATE TABLE finance_app (
    finance_id       VARCHAR(12)    NOT NULL,
    deal_number      VARCHAR(10)    NOT NULL,
    customer_id      INTEGER        NOT NULL,
    finance_type     VARCHAR(1)     NOT NULL,
    lender_code      VARCHAR(5),
    lender_name      VARCHAR(40),
    app_status       VARCHAR(2)     NOT NULL DEFAULT 'NW',
    amount_requested NUMERIC(11,2)  NOT NULL DEFAULT 0,
    amount_approved  NUMERIC(11,2),
    apr_requested    NUMERIC(5,3),
    apr_approved     NUMERIC(5,3),
    term_months      SMALLINT,
    monthly_payment  NUMERIC(9,2),
    down_payment     NUMERIC(11,2)  NOT NULL DEFAULT 0,
    credit_tier      VARCHAR(1),
    stipulations     VARCHAR(200),
    submitted_ts     TIMESTAMP,
    decision_ts      TIMESTAMP,
    funded_ts        TIMESTAMP,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (finance_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);

CREATE TABLE finance_product (
    deal_number      VARCHAR(10)    NOT NULL,
    product_seq      SMALLINT       NOT NULL,
    product_type     VARCHAR(3)     NOT NULL,
    product_name     VARCHAR(40)    NOT NULL,
    provider         VARCHAR(40),
    term_months      SMALLINT,
    mileage_limit    INTEGER,
    retail_price     NUMERIC(9,2)   NOT NULL,
    dealer_cost      NUMERIC(9,2)   NOT NULL,
    gross_profit     NUMERIC(9,2)   NOT NULL,
    PRIMARY KEY (deal_number, product_seq),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);

CREATE TABLE lease_terms (
    finance_id       VARCHAR(12)    NOT NULL,
    residual_pct     NUMERIC(5,2)   NOT NULL,
    residual_amt     NUMERIC(11,2)  NOT NULL,
    money_factor     NUMERIC(7,6)   NOT NULL,
    capitalized_cost NUMERIC(11,2)  NOT NULL,
    cap_cost_reduce  NUMERIC(11,2)  NOT NULL DEFAULT 0,
    adj_cap_cost     NUMERIC(11,2)  NOT NULL,
    depreciation_amt NUMERIC(11,2)  NOT NULL,
    finance_charge   NUMERIC(9,2)   NOT NULL,
    monthly_tax      NUMERIC(7,2)   NOT NULL DEFAULT 0,
    miles_per_year   INTEGER        NOT NULL DEFAULT 12000,
    excess_mile_chg  NUMERIC(5,3)   NOT NULL DEFAULT 0.25,
    disposition_fee  NUMERIC(7,2)   NOT NULL DEFAULT 395.00,
    acq_fee          NUMERIC(7,2)   NOT NULL DEFAULT 0,
    security_deposit NUMERIC(7,2)   NOT NULL DEFAULT 0,
    PRIMARY KEY (finance_id),
    FOREIGN KEY (finance_id) REFERENCES finance_app (finance_id)
);

CREATE TABLE fi_deal_product (
    deal_number      VARCHAR(10)    NOT NULL,
    product_seq      SMALLINT       NOT NULL,
    product_type     VARCHAR(3)     NOT NULL,
    product_name     VARCHAR(40)    NOT NULL,
    provider         VARCHAR(40),
    term_months      SMALLINT,
    mileage_limit    INTEGER,
    selling_price    NUMERIC(9,2)   NOT NULL,
    dealer_cost      NUMERIC(9,2)   NOT NULL,
    gross_profit     NUMERIC(9,2)   NOT NULL,
    PRIMARY KEY (deal_number, product_seq),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);
