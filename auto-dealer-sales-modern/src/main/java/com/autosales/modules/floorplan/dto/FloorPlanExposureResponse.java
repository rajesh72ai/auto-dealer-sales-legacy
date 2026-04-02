package com.autosales.modules.floorplan.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Floor plan exposure summary response with lender breakdown, age buckets, and new/used split.
 * Port of FPEXP00.cbl — floor plan exposure report transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanExposureResponse {

    private String dealerCode;

    private GrandTotals grandTotals;
    private List<LenderBreakdown> lenderBreakdown;
    private NewUsedSplit newUsedSplit;
    private AgeBuckets ageBuckets;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrandTotals {
        private Integer totalVehicles;
        private BigDecimal totalBalance;
        private BigDecimal totalInterest;
        private BigDecimal weightedAvgRate;
        private Integer avgDaysOnFloor;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LenderBreakdown {
        private String lenderId;
        private String lenderName;
        private Integer vehicleCount;
        private BigDecimal balance;
        private BigDecimal interest;
        private BigDecimal avgRate;
        private Integer avgDays;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NewUsedSplit {
        private Integer newCount;
        private Integer usedCount;
        private BigDecimal newBalance;
        private BigDecimal usedBalance;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AgeBuckets {
        private Integer count0to30;
        private Integer count31to60;
        private Integer count61to90;
        private Integer count91plus;
    }
}
