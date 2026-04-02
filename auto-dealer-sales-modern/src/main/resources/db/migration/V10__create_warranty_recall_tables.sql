-- V10: Warranty and recall domain tables
-- Tables: warranty, warranty_claim, recall_campaign, recall_vehicle, recall_notification

CREATE TABLE warranty (
    warranty_id      INTEGER        GENERATED ALWAYS AS IDENTITY,
    vin              VARCHAR(17)    NOT NULL,
    deal_number      VARCHAR(10)    NOT NULL,
    warranty_type    VARCHAR(2)     NOT NULL,
    start_date       DATE           NOT NULL,
    expiry_date      DATE           NOT NULL,
    mileage_limit    INTEGER        NOT NULL,
    deductible       NUMERIC(7,2)   NOT NULL DEFAULT 0,
    active_flag      VARCHAR(1)     NOT NULL DEFAULT 'Y',
    registered_ts    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (warranty_id),
    FOREIGN KEY (vin) REFERENCES vehicle (vin)
);

CREATE TABLE warranty_claim (
    claim_number     VARCHAR(8)     NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    dealer_code      VARCHAR(5)     NOT NULL,
    claim_type       VARCHAR(2)     NOT NULL,
    claim_date       DATE           NOT NULL,
    repair_date      DATE,
    labor_amt        NUMERIC(9,2)   NOT NULL DEFAULT 0,
    parts_amt        NUMERIC(9,2)   NOT NULL DEFAULT 0,
    total_claim      NUMERIC(9,2)   NOT NULL DEFAULT 0,
    claim_status     VARCHAR(2)     NOT NULL DEFAULT 'NW',
    technician_id    VARCHAR(8),
    repair_order_num VARCHAR(12),
    notes            VARCHAR(200),
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (claim_number),
    FOREIGN KEY (vin) REFERENCES vehicle (vin)
);

CREATE TABLE recall_campaign (
    recall_id        VARCHAR(10)    NOT NULL,
    nhtsa_num        VARCHAR(12),
    recall_desc      VARCHAR(200)   NOT NULL,
    severity         VARCHAR(1)     NOT NULL,
    affected_years   VARCHAR(40)    NOT NULL,
    affected_models  VARCHAR(100)   NOT NULL,
    remedy_desc      VARCHAR(200)   NOT NULL,
    remedy_avail_dt  DATE,
    announced_date   DATE           NOT NULL,
    total_affected   INTEGER        NOT NULL DEFAULT 0,
    total_completed  INTEGER        NOT NULL DEFAULT 0,
    campaign_status  VARCHAR(1)     NOT NULL DEFAULT 'A',
    created_ts       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (recall_id)
);

CREATE TABLE recall_vehicle (
    recall_id        VARCHAR(10)    NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    dealer_code      VARCHAR(5),
    recall_status    VARCHAR(2)     NOT NULL DEFAULT 'OP',
    notified_date    DATE,
    scheduled_date   DATE,
    completed_date   DATE,
    technician_id    VARCHAR(8),
    parts_ordered    VARCHAR(1)     NOT NULL DEFAULT 'N',
    parts_avail      VARCHAR(1)     NOT NULL DEFAULT 'N',
    PRIMARY KEY (recall_id, vin),
    FOREIGN KEY (recall_id) REFERENCES recall_campaign (recall_id)
);

CREATE TABLE recall_notification (
    notif_id         INTEGER        GENERATED ALWAYS AS IDENTITY,
    recall_id        VARCHAR(10)    NOT NULL,
    vin              VARCHAR(17)    NOT NULL,
    customer_id      INTEGER,
    notif_type       VARCHAR(1)     NOT NULL,
    notif_date       DATE           NOT NULL,
    response_flag    VARCHAR(1)     NOT NULL DEFAULT 'N',
    PRIMARY KEY (notif_id),
    FOREIGN KEY (recall_id) REFERENCES recall_campaign (recall_id)
);
