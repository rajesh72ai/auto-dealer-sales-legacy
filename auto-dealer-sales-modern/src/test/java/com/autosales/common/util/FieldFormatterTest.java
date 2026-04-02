package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link FieldFormatter} — currency, phone, SSN, percentage, name formatting.
 */
class FieldFormatterTest {

    private FieldFormatter formatter;

    @BeforeEach
    void setUp() {
        formatter = new FieldFormatter();
    }

    @Test
    void testFormatCurrency() {
        assertEquals("$1,234,567.89", formatter.formatCurrency(new BigDecimal("1234567.89")));
        assertEquals("$0.00", formatter.formatCurrency(null));
        assertEquals("-$500.00", formatter.formatCurrency(new BigDecimal("-500.00")));
    }

    @Test
    void testFormatPhone() {
        assertEquals("303-555-1234", formatter.formatPhone("3035551234"));
        // With non-digit characters stripped
        assertEquals("303-555-1234", formatter.formatPhone("(303) 555-1234"));
        // Not 10 digits — returns as-is
        assertEquals("12345", formatter.formatPhone("12345"));
        // Null/blank
        assertEquals("", formatter.formatPhone(null));
        assertEquals("", formatter.formatPhone(""));
    }

    @Test
    void testMaskSsn() {
        assertEquals("XXX-XX-1234", formatter.maskSsn("1234"));
        // Full SSN passed — should extract last 4
        assertEquals("XXX-XX-6789", formatter.maskSsn("123456789"));
        // Null
        assertEquals("XXX-XX-XXXX", formatter.maskSsn(null));
        // Blank
        assertEquals("XXX-XX-XXXX", formatter.maskSsn(""));
    }

    @Test
    void testFormatPercentage() {
        assertEquals("5.25%", formatter.formatPercentage(new BigDecimal("5.25")));
        assertEquals("0.00%", formatter.formatPercentage(null));
        assertEquals("10.00%", formatter.formatPercentage(new BigDecimal("10")));
    }

    @Test
    void testFormatProperName() {
        assertEquals("McDonald", formatter.formatProperName("mcdonald"));
        assertEquals("McDonald", formatter.formatProperName("MCDONALD"));
        assertEquals("O'Brien", formatter.formatProperName("O'BRIEN"));
        assertEquals("MacArthur", formatter.formatProperName("MACARTHUR"));
        assertEquals("Smith", formatter.formatProperName("SMITH"));
        assertEquals("", formatter.formatProperName(null));
        assertEquals("", formatter.formatProperName(""));
    }
}
