package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgingReportResponse {

    private String dealerCode;
    private int totalVehicles;
    private BigDecimal totalValue;
    private int avgDaysInStock;
    private List<AgingBucket> buckets;
    private List<VehicleListResponse> agedVehicles;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AgingBucket {
        private String range;
        private int count;
        private BigDecimal value;
        private int avgDays;
        private BigDecimal pctOfTotal;
    }
}
