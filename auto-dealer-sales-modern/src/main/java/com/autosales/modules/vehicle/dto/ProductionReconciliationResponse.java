package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductionReconciliationResponse {

    private long totalProduced;
    private long totalAllocated;
    private long totalShipped;
    private long totalDelivered;
    private List<ReconciliationException> exceptions;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReconciliationException {
        private String vin;
        private String productionStatus;
        private String vehicleStatus;
        private String reasonCode;
        private String reasonDesc;
        private int daysSinceBuild;
        private String plantCode;
    }
}
