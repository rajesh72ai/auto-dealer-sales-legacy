package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidationReportResponse {

    private LocalDateTime generatedAt;
    private Integer totalExceptions;
    private List<ValidationException> orphanedDeals;
    private List<ValidationException> orphanedVehicles;
    private List<ValidationException> invalidVins;
    private List<ValidationException> duplicateCustomers;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ValidationException {
        private String entityType;
        private String entityId;
        private String description;
        private String severity;
    }
}
