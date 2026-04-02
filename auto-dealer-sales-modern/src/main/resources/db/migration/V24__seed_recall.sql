-- ============================================================
-- V24: Seed data for recall domain
-- 3 recall_campaign records (Ford, Toyota, BMW)
-- 10 recall_vehicle records across 3 campaigns
-- 8 recall_notification records for customer-owned vehicles
-- ============================================================

-- Campaign 1: Ford F-150 tailgate latch (Critical)
INSERT INTO recall_campaign (RECALL_ID, NHTSA_NUM, RECALL_DESC, SEVERITY, AFFECTED_YEARS, AFFECTED_MODELS, REMEDY_DESC, REMEDY_AVAIL_DT, ANNOUNCED_DATE, TOTAL_AFFECTED, TOTAL_COMPLETED, CAMPAIGN_STATUS)
VALUES ('RCL2025001', '25V-412     ', 'Tailgate latch may not engage properly, allowing tailgate to open unexpectedly while driving. Risk of cargo loss and rear-end collision.', 'C', '2025', 'Ford F-150 XLT', 'Replace tailgate latch assembly and actuator. Reprogram body control module.', '2025-08-15', '2025-08-01', 125000, 42000, 'A');

-- Campaign 2: Toyota RAV4 hybrid battery sensor (Medium)
INSERT INTO recall_campaign (RECALL_ID, NHTSA_NUM, RECALL_DESC, SEVERITY, AFFECTED_YEARS, AFFECTED_MODELS, REMEDY_DESC, REMEDY_AVAIL_DT, ANNOUNCED_DATE, TOTAL_AFFECTED, TOTAL_COMPLETED, CAMPAIGN_STATUS)
VALUES ('RCL2025002', '25V-556     ', 'Hybrid battery temperature sensor may provide incorrect readings, potentially causing premature battery degradation and reduced fuel economy.', 'M', '2025', 'Toyota RAV4 XLE Premium', 'Replace battery temperature sensor module and update hybrid system software.', '2025-09-01', '2025-08-15', 85000, 18000, 'A');

-- Campaign 3: BMW 3-Series seat belt pretensioner (High)
INSERT INTO recall_campaign (RECALL_ID, NHTSA_NUM, RECALL_DESC, SEVERITY, AFFECTED_YEARS, AFFECTED_MODELS, REMEDY_DESC, REMEDY_AVAIL_DT, ANNOUNCED_DATE, TOTAL_AFFECTED, TOTAL_COMPLETED, CAMPAIGN_STATUS)
VALUES ('RCL2025003', '25V-678     ', 'Front seat belt pretensioner may not deploy correctly in certain frontal crash scenarios due to wiring harness routing issue.', 'H', '2025', 'BMW 330i xDrive', 'Reroute and replace front seat belt pretensioner wiring harness on both sides.', NULL, '2025-09-15', 45000, 0, 'P');

-- Recall Vehicles
-- Campaign 1 (Ford F-150) - 4 affected vehicles at DLR01
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, SCHEDULED_DATE, COMPLETED_DATE, TECHNICIAN_ID, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025001', '1FTFW1E53NFA00101', 'DLR01', 'CM', '2025-08-05', '2025-08-20', '2025-08-22', 'TSMITH01', 'Y', 'Y');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, SCHEDULED_DATE, COMPLETED_DATE, TECHNICIAN_ID, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025001', '1FTFW1E53NFA00102', 'DLR01', 'SC', '2025-08-05', '2025-10-10', NULL, NULL, 'Y', 'Y');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025001', '1FTFW1E53NFA00103', 'DLR01', 'OP', '2025-08-05', 'Y', 'Y');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025001', '1FMCU9J93NUA00301', 'DLR01', 'OP', '2025-08-05', 'N', 'N');

-- Campaign 2 (Toyota RAV4) - 3 affected vehicles at DLR02
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, SCHEDULED_DATE, COMPLETED_DATE, TECHNICIAN_ID, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025002', '2T3WFREV5NW200201', 'DLR02', 'CM', '2025-08-20', '2025-09-05', '2025-09-07', 'DJONES02', 'Y', 'Y');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, SCHEDULED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025002', '2T3WFREV5NW200202', 'DLR02', 'SC', '2025-08-20', '2025-10-15', 'Y', 'Y');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025002', '2T3WFREV5NW200203', 'DLR02', 'OP', '2025-08-20', 'N', 'N');

-- Campaign 3 (BMW 330i) - 3 affected vehicles at DLR05 (parts pending)
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025003', 'WBA5R1C50NFJ00101', 'DLR05', 'OP', '2025-09-20', 'Y', 'N');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025003', 'WBA5R1C50NFJ00102', 'DLR05', 'OP', '2025-09-20', 'Y', 'N');
INSERT INTO recall_vehicle (RECALL_ID, VIN, DEALER_CODE, RECALL_STATUS, NOTIFIED_DATE, PARTS_ORDERED, PARTS_AVAIL) VALUES ('RCL2025003', 'WBA5R1C50NFJ00104', 'DLR05', 'OP', '2025-09-20', 'Y', 'N');

-- Recall Notifications
-- Campaign 1 notifications (customer-owned vehicles)
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025001', '1FMCU9J93NUA00301', 1, 'M', '2025-08-10', 'N');
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025001', '1FMCU9J93NUA00301', 1, 'E', '2025-08-10', 'N');

-- Campaign 2 notifications
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025002', '2T3WFREV5NW200202', 8, 'M', '2025-08-25', 'Y');
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025002', '2T3WFREV5NW200202', 8, 'E', '2025-08-25', 'Y');
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025002', '2T3WFREV5NW200202', 8, 'P', '2025-09-01', 'Y');

-- Campaign 3 notifications (sold vehicles)
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025003', 'WBA5R1C50NFJ00101', 25, 'M', '2025-09-25', 'N');
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025003', 'WBA5R1C50NFJ00101', 25, 'E', '2025-09-25', 'N');
INSERT INTO recall_notification (RECALL_ID, VIN, CUSTOMER_ID, NOTIF_TYPE, NOTIF_DATE, RESPONSE_FLAG) VALUES ('RCL2025003', 'WBA5R1C50NFJ00104', 27, 'M', '2025-09-25', 'N');
