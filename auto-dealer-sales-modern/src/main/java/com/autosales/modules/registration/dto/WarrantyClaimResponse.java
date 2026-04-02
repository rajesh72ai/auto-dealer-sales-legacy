package com.autosales.modules.registration.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WarrantyClaimResponse {

    private String claimNumber;
    private String vin;
    private String dealerCode;
    private String claimType;
    private LocalDate claimDate;
    private LocalDate repairDate;
    private BigDecimal laborAmt;
    private BigDecimal partsAmt;
    private BigDecimal totalClaim;
    private String claimStatus;
    private String technicianId;
    private String repairOrderNum;
    private String notes;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private String claimTypeName;
    private String claimStatusName;
    private String formattedLabor;
    private String formattedParts;
    private String formattedTotal;
}
