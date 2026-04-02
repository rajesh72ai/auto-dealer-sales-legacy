-- V6: Customer domain tables
-- Tables: customer, customer_lead, credit_check

CREATE TABLE customer (
    customer_id      INTEGER        GENERATED ALWAYS AS IDENTITY,
    first_name       VARCHAR(30)    NOT NULL,
    last_name        VARCHAR(30)    NOT NULL,
    middle_init      VARCHAR(1),
    date_of_birth    DATE,
    ssn_last4        VARCHAR(4),
    drivers_license  VARCHAR(20),
    dl_state         VARCHAR(2),
    address_line1    VARCHAR(50)    NOT NULL,
    address_line2    VARCHAR(50),
    city             VARCHAR(30)    NOT NULL,
    state_code       VARCHAR(2)     NOT NULL,
    zip_code         VARCHAR(10)    NOT NULL,
    home_phone       VARCHAR(10),
    cell_phone       VARCHAR(10),
    email            VARCHAR(60),
    employer_name    VARCHAR(40),
    annual_income    NUMERIC(11,2),
    customer_type    VARCHAR(1)     NOT NULL DEFAULT 'I',
    source_code      VARCHAR(3),
    dealer_code      VARCHAR(5)     NOT NULL,
    assigned_sales   VARCHAR(8),
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id)
);

CREATE TABLE customer_lead (
    lead_id          INTEGER        GENERATED ALWAYS AS IDENTITY,
    customer_id      INTEGER        NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    lead_source      VARCHAR(3)     NOT NULL,
    interest_model   VARCHAR(6),
    interest_year    SMALLINT,
    lead_status      VARCHAR(2)     NOT NULL DEFAULT 'NW',
    assigned_sales   VARCHAR(8)     NOT NULL,
    follow_up_date   DATE,
    last_contact_dt  DATE,
    contact_count    SMALLINT       NOT NULL DEFAULT 0,
    notes            VARCHAR(200),
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (lead_id),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);

CREATE TABLE credit_check (
    credit_id        INTEGER        GENERATED ALWAYS AS IDENTITY,
    customer_id      INTEGER        NOT NULL,
    bureau_code      VARCHAR(2)     NOT NULL,
    credit_score     SMALLINT,
    credit_tier      VARCHAR(1),
    request_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_ts      TIMESTAMP,
    status           VARCHAR(2)     NOT NULL DEFAULT 'RQ',
    monthly_debt     NUMERIC(9,2),
    monthly_income   NUMERIC(9,2),
    dti_ratio        NUMERIC(5,2),
    expiry_date      DATE,
    PRIMARY KEY (credit_id),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);
