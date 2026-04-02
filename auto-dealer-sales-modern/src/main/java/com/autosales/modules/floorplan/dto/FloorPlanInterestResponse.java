package com.autosales.modules.floorplan.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Floor plan interest accrual response with per-vehicle detail and batch summary.
 * Port of FPINT00.cbl — floor plan interest calculation result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanInterestResponse {

    private String mode;
    private Integer processedCount;
    private Integer updatedCount;
    private Integer curtailmentWarningCount;
    private Integer errorCount;
    private BigDecimal totalInterestAmount;

    private List<InterestDetail> details;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InterestDetail {
        private String vin;
        private BigDecimal dailyInterest;
        private BigDecimal newAccrued;
        private Integer daysToCurtailment;
        private boolean warning;
    }
}
