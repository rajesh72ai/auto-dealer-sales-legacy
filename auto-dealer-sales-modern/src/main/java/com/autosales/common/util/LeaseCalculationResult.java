package com.autosales.common.util;

import java.math.BigDecimal;

/**
 * Lease calculation result.
 * Port of COMLESL0.cbl lease output area.
 */
public record LeaseCalculationResult(
        BigDecimal residualAmount,
        BigDecimal adjustedCapCost,
        BigDecimal monthlyDepreciation,
        BigDecimal monthlyFinanceCharge,
        BigDecimal monthlyTax,
        BigDecimal totalMonthlyPayment,
        BigDecimal driveOffAmount,
        BigDecimal totalCost,
        BigDecimal equivalentApr
) {
}
