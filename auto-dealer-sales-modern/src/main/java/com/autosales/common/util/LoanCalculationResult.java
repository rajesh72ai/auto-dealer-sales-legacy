package com.autosales.common.util;

import java.math.BigDecimal;
import java.util.List;

/**
 * Auto loan calculation result with amortization schedule.
 * Port of COMLONL0.cbl loan output area.
 */
public record LoanCalculationResult(
        BigDecimal monthlyPayment,
        BigDecimal totalInterest,
        BigDecimal totalOfPayments,
        List<AmortizationEntry> amortizationSchedule
) {
}
