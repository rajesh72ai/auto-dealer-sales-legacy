package com.autosales.modules.admin.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SalespersonResponse {

    private String salespersonId;
    private String salespersonName;
    private String dealerCode;
    private LocalDate hireDate;
    private LocalDate terminationDate;
    private String commissionPlan;
    private String activeFlag;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // From relationship
    private String dealerName;
}
