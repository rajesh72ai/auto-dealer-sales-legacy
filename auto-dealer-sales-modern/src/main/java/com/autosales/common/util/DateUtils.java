package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.Period;
import java.time.temporal.ChronoUnit;

/**
 * Date utility methods for business-day arithmetic, age calculation,
 * and day-span computation.
 * Port of COMDTEL0.cbl — common date processing routines.
 */
@Component
public class DateUtils {

    /**
     * Calculate the number of days between two dates.
     *
     * @param d1 start date (inclusive)
     * @param d2 end date (exclusive)
     * @return number of days (negative if d2 is before d1)
     */
    public long daysBetween(LocalDate d1, LocalDate d2) {
        if (d1 == null || d2 == null) {
            throw new IllegalArgumentException("Dates must not be null");
        }
        return ChronoUnit.DAYS.between(d1, d2);
    }

    /**
     * Add the specified number of business days (Monday-Friday) to the start date.
     * Saturdays and Sundays are skipped. Does not account for holidays.
     *
     * @param start    the starting date
     * @param days     number of business days to add (may be negative)
     * @return the resulting date after skipping weekends
     */
    public LocalDate addBusinessDays(LocalDate start, int days) {
        if (start == null) {
            throw new IllegalArgumentException("Start date must not be null");
        }
        if (days == 0) {
            return start;
        }

        int direction = days > 0 ? 1 : -1;
        int remaining = Math.abs(days);
        LocalDate current = start;

        while (remaining > 0) {
            current = current.plusDays(direction);
            DayOfWeek dow = current.getDayOfWeek();
            if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY) {
                remaining--;
            }
        }
        return current;
    }

    /**
     * Calculate a person's age in whole years as of a given date.
     *
     * @param birthDate the date of birth
     * @param asOfDate  the reference date
     * @return age in completed years
     */
    public int calculateAge(LocalDate birthDate, LocalDate asOfDate) {
        if (birthDate == null || asOfDate == null) {
            throw new IllegalArgumentException("Dates must not be null");
        }
        if (asOfDate.isBefore(birthDate)) {
            throw new IllegalArgumentException("As-of date must not be before birth date");
        }
        return Period.between(birthDate, asOfDate).getYears();
    }
}
