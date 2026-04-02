package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReconciliationResponse {

    private String dealerCode;
    private LocalDate reconciliationDate;
    private int totalModels;
    private List<Discrepancy> discrepancies;
    private int totalVariance;
    private boolean reconciled;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Discrepancy {
        private Short modelYear;
        private String makeCode;
        private String modelCode;
        private String modelDesc;
        private int systemCount;
        private int actualCount;
        private int variance;
    }
}
