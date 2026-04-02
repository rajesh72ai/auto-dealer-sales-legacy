-- V7: Sales domain tables
-- Tables: sales_deal, deal_line_item, trade_in, incentive_applied, sales_approval

CREATE TABLE sales_deal (
    deal_number      VARCHAR(10)    NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    customer_id      INTEGER        NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    salesperson_id   VARCHAR(8)     NOT NULL,
    sales_manager_id VARCHAR(8),
    deal_type        VARCHAR(1)     NOT NULL,
    deal_status      VARCHAR(2)     NOT NULL DEFAULT 'WS',
    vehicle_price    NUMERIC(11,2)  NOT NULL DEFAULT 0,
    total_options    NUMERIC(9,2)   NOT NULL DEFAULT 0,
    destination_fee  NUMERIC(7,2)   NOT NULL DEFAULT 0,
    subtotal         NUMERIC(11,2)  NOT NULL DEFAULT 0,
    trade_allow      NUMERIC(11,2)  NOT NULL DEFAULT 0,
    trade_payoff     NUMERIC(11,2)  NOT NULL DEFAULT 0,
    net_trade        NUMERIC(11,2)  NOT NULL DEFAULT 0,
    rebates_applied  NUMERIC(9,2)   NOT NULL DEFAULT 0,
    discount_amt     NUMERIC(9,2)   NOT NULL DEFAULT 0,
    doc_fee          NUMERIC(7,2)   NOT NULL DEFAULT 0,
    state_tax        NUMERIC(9,2)   NOT NULL DEFAULT 0,
    county_tax       NUMERIC(9,2)   NOT NULL DEFAULT 0,
    city_tax         NUMERIC(9,2)   NOT NULL DEFAULT 0,
    title_fee        NUMERIC(7,2)   NOT NULL DEFAULT 0,
    reg_fee          NUMERIC(7,2)   NOT NULL DEFAULT 0,
    total_price      NUMERIC(11,2)  NOT NULL DEFAULT 0,
    down_payment     NUMERIC(11,2)  NOT NULL DEFAULT 0,
    amount_financed  NUMERIC(11,2)  NOT NULL DEFAULT 0,
    front_gross      NUMERIC(11,2)  NOT NULL DEFAULT 0,
    back_gross       NUMERIC(11,2)  NOT NULL DEFAULT 0,
    total_gross      NUMERIC(11,2)  NOT NULL DEFAULT 0,
    deal_date        DATE,
    delivery_date    DATE,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (deal_number),
    FOREIGN KEY (vin) REFERENCES vehicle (vin),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);

CREATE TABLE deal_line_item (
    deal_number      VARCHAR(10)    NOT NULL,
    line_seq         SMALLINT       NOT NULL,
    line_type        VARCHAR(2)     NOT NULL,
    description      VARCHAR(40)    NOT NULL,
    amount           NUMERIC(11,2)  NOT NULL,
    cost             NUMERIC(11,2)  NOT NULL DEFAULT 0,
    taxable_flag     VARCHAR(1)     NOT NULL DEFAULT 'Y',
    PRIMARY KEY (deal_number, line_seq),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);

CREATE TABLE trade_in (
    trade_id         INTEGER        GENERATED ALWAYS AS IDENTITY,
    deal_number      VARCHAR(10)    NOT NULL,
    vin              VARCHAR(17),
    trade_year       SMALLINT       NOT NULL,
    trade_make       VARCHAR(20)    NOT NULL,
    trade_model      VARCHAR(30)    NOT NULL,
    trade_color      VARCHAR(15),
    odometer         INTEGER        NOT NULL,
    condition_code   VARCHAR(1)     NOT NULL,
    acv_amount       NUMERIC(11,2)  NOT NULL,
    allowance_amt    NUMERIC(11,2)  NOT NULL,
    over_allow       NUMERIC(9,2)   NOT NULL DEFAULT 0,
    payoff_amt       NUMERIC(11,2)  NOT NULL DEFAULT 0,
    payoff_bank      VARCHAR(40),
    payoff_acct      VARCHAR(20),
    appraised_by     VARCHAR(8)     NOT NULL,
    appraised_ts     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (trade_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);

CREATE TABLE incentive_applied (
    deal_number      VARCHAR(10)    NOT NULL,
    incentive_id     VARCHAR(10)    NOT NULL,
    amount_applied   NUMERIC(9,2)   NOT NULL,
    applied_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (deal_number, incentive_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number),
    FOREIGN KEY (incentive_id) REFERENCES incentive_program (incentive_id)
);

CREATE TABLE sales_approval (
    approval_id      INTEGER        GENERATED ALWAYS AS IDENTITY,
    deal_number      VARCHAR(10)    NOT NULL,
    approval_type    VARCHAR(2)     NOT NULL,
    approver_id      VARCHAR(8)     NOT NULL,
    approval_status  VARCHAR(1)     NOT NULL,
    comments         VARCHAR(200),
    approval_ts      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (approval_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number)
);
