package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link DateUtils} — days-between, business days, age calculation.
 */
class DateUtilsTest {

    private DateUtils dateUtils;

    @BeforeEach
    void setUp() {
        dateUtils = new DateUtils();
    }

    @Test
    void testDaysBetween() {
        LocalDate jan1 = LocalDate.of(2025, 1, 1);
        LocalDate jan31 = LocalDate.of(2025, 1, 31);
        assertEquals(30, dateUtils.daysBetween(jan1, jan31));

        // Full year
        LocalDate dec31 = LocalDate.of(2025, 12, 31);
        assertEquals(364, dateUtils.daysBetween(jan1, dec31));

        // Negative when d2 is before d1
        assertEquals(-30, dateUtils.daysBetween(jan31, jan1));
    }

    @Test
    void testAddBusinessDays() {
        // Monday 2025-01-06 + 5 business days = Friday 2025-01-10 (skips no weekends within Mon-Fri)
        LocalDate monday = LocalDate.of(2025, 1, 6);
        assertEquals(LocalDate.of(2025, 1, 13), dateUtils.addBusinessDays(monday, 5),
                "5 business days from Monday should land on the following Monday");

        // Friday 2025-01-10 + 1 business day = Monday 2025-01-13 (skips Saturday and Sunday)
        LocalDate friday = LocalDate.of(2025, 1, 10);
        assertEquals(LocalDate.of(2025, 1, 13), dateUtils.addBusinessDays(friday, 1),
                "1 business day from Friday should be Monday");

        // Zero days returns the same date
        assertEquals(monday, dateUtils.addBusinessDays(monday, 0));
    }

    @Test
    void testCalculateAge() {
        // Someone born on 1990-06-15, as of 2025-06-14 -> 34 (birthday hasn't happened yet)
        assertEquals(34, dateUtils.calculateAge(
                LocalDate.of(1990, 6, 15),
                LocalDate.of(2025, 6, 14)));

        // Same person, as of 2025-06-15 -> 35 (birthday today)
        assertEquals(35, dateUtils.calculateAge(
                LocalDate.of(1990, 6, 15),
                LocalDate.of(2025, 6, 15)));

        // Null inputs throw
        assertThrows(IllegalArgumentException.class, () ->
                dateUtils.calculateAge(null, LocalDate.now()));
    }
}
