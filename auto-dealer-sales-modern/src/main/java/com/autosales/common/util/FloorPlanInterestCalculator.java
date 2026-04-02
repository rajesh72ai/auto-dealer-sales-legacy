package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Year;
import java.time.temporal.ChronoUnit;

/**
 * Daily floor-plan interest calculation with multiple day-count bases.
 * Port of COMINTL0.cbl — floor-plan interest computation module.
 */
@Component
public class FloorPlanInterestCalculator {

    private static final MathContext MC = MathContext.DECIMAL128;
    private static final int DAILY_SCALE = 4;
    private static final int CUMULATIVE_SCALE = 2;

    private static final BigDecimal HUNDRED = new BigDecimal("100");
    private static final BigDecimal DAYS_360 = new BigDecimal("360");
    private static final BigDecimal DAYS_365 = new BigDecimal("365");
    private static final BigDecimal DAYS_366 = new BigDecimal("366");

    /** New vehicle curtailment threshold in days. */
    private static final long NEW_CURTAILMENT_DAYS = 90;
    /** Used vehicle curtailment threshold in days. */
    private static final long USED_CURTAILMENT_DAYS = 60;

    public enum DayCountBasis {
        /** 30/360 day-count convention. */
        THIRTY_360,
        /** Actual/365 fixed day-count convention. */
        ACTUAL_365,
        /** Actual/Actual day-count convention (leap-year aware). */
        ACTUAL_ACTUAL
    }

    /**
     * Calculate daily interest for a given principal and rate on a specific date.
     *
     * @param principal  the outstanding principal balance
     * @param annualRate the annual interest rate as a percentage (e.g., 5.25 for 5.25%)
     * @param basis      the day-count basis to use
     * @param calcDate   the calculation date (used for leap-year determination in ACTUAL_ACTUAL)
     * @return the daily interest amount, scaled to {@value DAILY_SCALE} decimal places
     */
    public BigDecimal calculateDailyInterest(BigDecimal principal, BigDecimal annualRate,
                                             DayCountBasis basis, LocalDate calcDate) {
        BigDecimal dailyRate = calculateDailyRate(annualRate, basis, calcDate);
        return principal.multiply(dailyRate, MC).setScale(DAILY_SCALE, RoundingMode.HALF_UP);
    }

    /**
     * Calculate the daily rate for the given basis.
     *
     * @param annualRate the annual rate as a percentage
     * @param basis      the day-count basis
     * @param calcDate   the calculation date
     * @return the daily rate as a decimal fraction, scaled to {@value DAILY_SCALE} places
     */
    public BigDecimal calculateDailyRate(BigDecimal annualRate, DayCountBasis basis, LocalDate calcDate) {
        BigDecimal divisor = switch (basis) {
            case THIRTY_360 -> DAYS_360;
            case ACTUAL_365 -> DAYS_365;
            case ACTUAL_ACTUAL -> Year.of(calcDate.getYear()).isLeap() ? DAYS_366 : DAYS_365;
        };
        return annualRate.divide(HUNDRED, MC).divide(divisor, DAILY_SCALE, RoundingMode.HALF_UP);
    }

    /**
     * Calculate cumulative interest over a date range [startDate, endDate) exclusive of endDate.
     *
     * @param principal  the outstanding principal balance
     * @param annualRate the annual interest rate as a percentage
     * @param basis      the day-count basis
     * @param startDate  the start date (inclusive)
     * @param endDate    the end date (exclusive)
     * @return the cumulative interest, scaled to {@value CUMULATIVE_SCALE} decimal places
     */
    public BigDecimal calculateRangeInterest(BigDecimal principal, BigDecimal annualRate,
                                             DayCountBasis basis, LocalDate startDate, LocalDate endDate) {
        if (startDate.isAfter(endDate) || startDate.isEqual(endDate)) {
            return BigDecimal.ZERO.setScale(CUMULATIVE_SCALE);
        }

        BigDecimal cumulative = BigDecimal.ZERO;
        LocalDate current = startDate;
        while (current.isBefore(endDate)) {
            cumulative = cumulative.add(calculateDailyInterest(principal, annualRate, basis, current), MC);
            current = current.plusDays(1);
        }
        return cumulative.setScale(CUMULATIVE_SCALE, RoundingMode.HALF_UP);
    }

    /**
     * Check whether a vehicle has reached its curtailment threshold.
     *
     * @param floorDate   the date the vehicle was floored
     * @param calcDate    the current calculation date
     * @param vehicleType "NEW" or "USED"
     * @return true if the number of days on floor exceeds the curtailment threshold
     */
    public boolean checkCurtailment(LocalDate floorDate, LocalDate calcDate, String vehicleType) {
        long daysOnFloor = ChronoUnit.DAYS.between(floorDate, calcDate);
        long threshold = "NEW".equalsIgnoreCase(vehicleType) ? NEW_CURTAILMENT_DAYS : USED_CURTAILMENT_DAYS;
        return daysOnFloor > threshold;
    }

    /**
     * Compute a full floor-plan interest result for a vehicle.
     *
     * @param principal   the outstanding principal balance
     * @param annualRate  the annual interest rate as a percentage
     * @param basis       the day-count basis
     * @param floorDate   the date the vehicle was floored
     * @param calcDate    the current calculation date
     * @param vehicleType "NEW" or "USED"
     * @return a {@link FloorPlanInterestResult} with all computed values
     */
    public FloorPlanInterestResult computeFloorPlanInterest(BigDecimal principal, BigDecimal annualRate,
                                                            DayCountBasis basis, LocalDate floorDate,
                                                            LocalDate calcDate, String vehicleType) {
        BigDecimal dailyRate = calculateDailyRate(annualRate, basis, calcDate);
        BigDecimal dailyInterest = calculateDailyInterest(principal, annualRate, basis, calcDate);
        BigDecimal cumulativeInterest = calculateRangeInterest(principal, annualRate, basis, floorDate, calcDate);
        long daysOnFloor = ChronoUnit.DAYS.between(floorDate, calcDate);
        boolean isCurtailed = checkCurtailment(floorDate, calcDate, vehicleType);

        return new FloorPlanInterestResult(dailyRate, dailyInterest, cumulativeInterest, daysOnFloor, isCurtailed);
    }
}
