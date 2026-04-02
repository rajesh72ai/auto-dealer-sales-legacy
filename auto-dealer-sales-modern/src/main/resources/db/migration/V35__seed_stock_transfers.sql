-- V35: Seed additional stock transfers (3 pending/approved + 1 more completed)
-- Statuses: RQ (Requested), AP (Approved), CM (Completed), RJ (Rejected)

INSERT INTO stock_transfer (from_dealer, to_dealer, vin, transfer_status, requested_by, approved_by, requested_ts, approved_ts, completed_ts) VALUES
-- Pending request: DLR02 requesting a Civic from DLR03
('DLR03', 'DLR02', '19XFC1F38NE500103', 'RQ', 'DJONES02', NULL, '2025-10-01 09:30:00', NULL, NULL),

-- Approved, in transit: DLR04 getting an X5 from DLR05
('DLR05', 'DLR04', '5UXCR6C05NLL00203', 'AP', 'MBROWN04', 'EHART005', '2025-09-28 14:00:00', '2025-09-29 10:15:00', NULL),

-- Completed: DLR01 sent F-150 to DLR04
('DLR01', 'DLR04', '1FTFW1E53PFA00201', 'CM', 'WCLARK04', 'JPATTER1', '2025-09-15 11:00:00', '2025-09-16 08:30:00', '2025-09-19 16:00:00'),

-- Rejected: DLR02 wanted a Silverado from DLR04 but denied
('DLR04', 'DLR02', '1GCUYEED5NZ900103', 'RJ', 'DJONES02', 'WCLARK04', '2025-09-20 10:00:00', '2025-09-21 09:00:00', NULL);
