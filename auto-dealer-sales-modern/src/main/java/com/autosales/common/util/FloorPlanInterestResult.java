package com.autosales.common.util;

import java.math.BigDecimal;

/**
 * Floor-plan interest calculation result.
 * Port of COMINTL0.cbl interest output area.
 */
public record FloorPlanInterestResult(
        BigDecimal dailyRate,
        BigDecimal dailyInterest,
        BigDecimal cumulativeInterest,
        long daysOnFloor,
        boolean isCurtailed
) {
}
