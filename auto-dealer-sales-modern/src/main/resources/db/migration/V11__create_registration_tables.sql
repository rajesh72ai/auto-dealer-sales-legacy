-- V11: Registration and title domain tables
-- Tables: registration, title_status

CREATE TABLE registration (
    reg_id           VARCHAR(12)    NOT NULL,
    deal_number      VARCHAR(10)    NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    customer_id      INTEGER        NOT NULL,
    reg_state        VARCHAR(2)     NOT NULL,
    reg_type         VARCHAR(2)     NOT NULL,
    plate_number     VARCHAR(10),
    title_number     VARCHAR(20),
    lien_holder      VARCHAR(60),
    lien_holder_addr VARCHAR(100),
    reg_status       VARCHAR(2)     NOT NULL DEFAULT 'PR',
    submission_date  DATE,
    issued_date      DATE,
    reg_fee_paid     NUMERIC(7,2)   NOT NULL DEFAULT 0,
    title_fee_paid   NUMERIC(7,2)   NOT NULL DEFAULT 0,
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (reg_id),
    FOREIGN KEY (deal_number) REFERENCES sales_deal (deal_number),
    FOREIGN KEY (vin) REFERENCES vehicle (vin),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);

CREATE TABLE title_status (
    reg_id           VARCHAR(12)    NOT NULL,
    status_seq       SMALLINT       NOT NULL,
    status_code      VARCHAR(2)     NOT NULL,
    status_desc      VARCHAR(60),
    status_ts        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (reg_id, status_seq),
    FOREIGN KEY (reg_id) REFERENCES registration (reg_id)
);
