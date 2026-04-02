package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.util.Locale;

/**
 * Field formatting utilities for display: currency, phone, SSN mask,
 * VIN grouping, percentages, rates, and proper-case names.
 * Port of COMFMTL0.cbl — common field formatting routine.
 */
@Component
public class FieldFormatter {

    private static final NumberFormat CURRENCY_FORMAT;

    static {
        CURRENCY_FORMAT = NumberFormat.getCurrencyInstance(Locale.US);
        CURRENCY_FORMAT.setMinimumFractionDigits(2);
        CURRENCY_FORMAT.setMaximumFractionDigits(2);
    }

    /**
     * Format a BigDecimal amount as US currency: "$1,234,567.89".
     * Null returns "$0.00". Negative values are shown as "-$1,234.56".
     */
    public String formatCurrency(BigDecimal amount) {
        if (amount == null) {
            amount = BigDecimal.ZERO;
        }
        // NumberFormat.getCurrencyInstance handles negative with parentheses by default;
        // we normalize to minus-sign format for clarity.
        BigDecimal rounded = amount.setScale(2, RoundingMode.HALF_UP);
        if (rounded.signum() < 0) {
            return "-" + CURRENCY_FORMAT.format(rounded.negate());
        }
        return CURRENCY_FORMAT.format(rounded);
    }

    /**
     * Format a 10-digit phone number as "303-555-1234".
     * Non-digit characters are stripped first. Returns the input unchanged
     * if it does not resolve to exactly 10 digits.
     */
    public String formatPhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return "";
        }
        String digits = phone.replaceAll("\\D", "");
        if (digits.length() != 10) {
            return phone; // return as-is if not 10 digits
        }
        return digits.substring(0, 3) + "-" + digits.substring(3, 6) + "-" + digits.substring(6);
    }

    /**
     * Mask an SSN showing only the last 4 digits: "XXX-XX-1234".
     *
     * @param ssn4 the last 4 digits of the SSN
     */
    public String maskSsn(String ssn4) {
        if (ssn4 == null || ssn4.isBlank()) {
            return "XXX-XX-XXXX";
        }
        String digits = ssn4.replaceAll("\\D", "");
        if (digits.length() > 4) {
            digits = digits.substring(digits.length() - 4);
        }
        return "XXX-XX-" + digits;
    }

    /**
     * Format a VIN with visual grouping: "WMI-VDSCH-C-VIS"
     * (positions 1-3, 4-8, 9, 10-17).
     */
    public String formatVin(String vin) {
        if (vin == null || vin.trim().length() != 17) {
            return vin != null ? vin : "";
        }
        String v = vin.toUpperCase().trim();
        return v.substring(0, 3) + "-" + v.substring(3, 8) + "-" + v.charAt(8) + "-" + v.substring(9);
    }

    /**
     * Format a BigDecimal as a percentage: "5.25%".
     * Null returns "0.00%".
     */
    public String formatPercentage(BigDecimal pct) {
        if (pct == null) {
            pct = BigDecimal.ZERO;
        }
        return pct.setScale(2, RoundingMode.HALF_UP).toPlainString() + "%";
    }

    /**
     * Format an interest rate to 4 decimal places: "5.2500".
     * Null returns "0.0000".
     */
    public String formatRate(BigDecimal rate) {
        if (rate == null) {
            rate = BigDecimal.ZERO;
        }
        return rate.setScale(4, RoundingMode.HALF_UP).toPlainString();
    }

    /**
     * Format a name in proper case with special handling for
     * Mc, Mac, and O' prefixes.
     * <p>Examples: "MCDONALD" -> "McDonald", "O'BRIEN" -> "O'Brien",
     * "MACARTHUR" -> "MacArthur", "SMITH" -> "Smith".</p>
     */
    public String formatProperName(String name) {
        if (name == null || name.isBlank()) {
            return "";
        }

        String[] parts = name.trim().split("\\s+");
        StringBuilder result = new StringBuilder();

        for (int i = 0; i < parts.length; i++) {
            if (i > 0) {
                result.append(' ');
            }
            result.append(properCaseWord(parts[i]));
        }
        return result.toString();
    }

    private String properCaseWord(String word) {
        if (word.isEmpty()) {
            return word;
        }

        String upper = word.toUpperCase();
        String lower = word.toLowerCase();

        // Handle O' prefix (e.g., O'BRIEN -> O'Brien)
        int apostrophe = upper.indexOf('\'');
        if (apostrophe == 1 && upper.charAt(0) == 'O' && upper.length() > 2) {
            return "O'" + Character.toUpperCase(lower.charAt(2))
                    + (lower.length() > 3 ? lower.substring(3) : "");
        }

        // Handle Mc prefix (e.g., MCDONALD -> McDonald)
        if (upper.startsWith("MC") && upper.length() > 2) {
            return "Mc" + Character.toUpperCase(lower.charAt(2))
                    + (lower.length() > 3 ? lower.substring(3) : "");
        }

        // Handle Mac prefix (e.g., MACARTHUR -> MacArthur)
        // Only apply if the word is at least 5 chars to avoid false positives like "Mace"
        if (upper.startsWith("MAC") && upper.length() >= 5) {
            return "Mac" + Character.toUpperCase(lower.charAt(3))
                    + (lower.length() > 4 ? lower.substring(4) : "");
        }

        // Standard proper case
        return Character.toUpperCase(lower.charAt(0))
                + (lower.length() > 1 ? lower.substring(1) : "");
    }
}
