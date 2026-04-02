-- V26__seed_stock_positions.sql
-- Populate stock_position from existing vehicle data.
-- Aggregates vehicle counts by dealer/year/make/model and status.

INSERT INTO stock_position (dealer_code, model_year, make_code, model_code,
    on_hand_count, in_transit_count, allocated_count, on_hold_count,
    sold_mtd, sold_ytd, reorder_point, updated_ts)
SELECT
    v.dealer_code,
    v.model_year,
    v.make_code,
    v.model_code,
    COALESCE(SUM(CASE WHEN v.vehicle_status = 'AV' THEN 1 ELSE 0 END), 0) AS on_hand,
    COALESCE(SUM(CASE WHEN v.vehicle_status = 'IT' THEN 1 ELSE 0 END), 0) AS in_transit,
    COALESCE(SUM(CASE WHEN v.vehicle_status = 'AL' THEN 1 ELSE 0 END), 0) AS allocated,
    COALESCE(SUM(CASE WHEN v.vehicle_status = 'HD' THEN 1 ELSE 0 END), 0) AS on_hold,
    COALESCE(SUM(CASE WHEN v.vehicle_status = 'SD' THEN 1 ELSE 0 END), 0) AS sold_mtd,
    COALESCE(SUM(CASE WHEN v.vehicle_status = 'SD' THEN 1 ELSE 0 END), 0) AS sold_ytd,
    3 AS reorder_point,
    CURRENT_TIMESTAMP
FROM vehicle v
WHERE v.dealer_code IS NOT NULL
GROUP BY v.dealer_code, v.model_year, v.make_code, v.model_code;
