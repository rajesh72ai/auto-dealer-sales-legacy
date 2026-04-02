package com.autosales.common.util;

import java.math.BigDecimal;

/**
 * Single month entry in a loan amortization schedule.
 * Port of COMLONL0.cbl amortization table row.
 */
public record AmortizationEntry(
        int month,
        BigDecimal payment,
        BigDecimal principalPortion,
        BigDecimal interestPortion,
        BigDecimal cumulativeInterest,
        BigDecimal remainingBalance
) {
}
