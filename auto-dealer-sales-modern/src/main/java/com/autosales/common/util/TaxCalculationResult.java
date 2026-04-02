package com.autosales.common.util;

import java.math.BigDecimal;

/**
 * Multi-jurisdiction tax calculation result.
 * Port of COMTAXL0.cbl tax output area.
 */
public record TaxCalculationResult(
        BigDecimal stateTax,
        BigDecimal countyTax,
        BigDecimal cityTax,
        BigDecimal docFee,
        BigDecimal titleFee,
        BigDecimal regFee,
        BigDecimal totalTax,
        BigDecimal totalFees,
        BigDecimal grandTotal
) {
}
