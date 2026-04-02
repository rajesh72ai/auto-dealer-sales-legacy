package com.autosales.common.util;

import java.math.BigDecimal;

/**
 * Deal pricing gross analysis result.
 * Port of COMPRCL0.cbl pricing output area.
 */
public record PricingResult(
        BigDecimal msrp,
        BigDecimal invoice,
        BigDecimal totalMsrp,
        BigDecimal totalInvoice,
        BigDecimal holdback,
        BigDecimal dealerCost,
        BigDecimal frontGross,
        BigDecimal backGross,
        BigDecimal totalGross,
        BigDecimal marginPct
) {
}
