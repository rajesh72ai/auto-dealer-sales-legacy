package com.autosales.modules.admin.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IncentiveProgramResponse {

    private String incentiveId;
    private String incentiveName;
    private String incentiveType;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String regionCode;
    private BigDecimal amount;
    private BigDecimal rateOverride;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer maxUnits;
    private String stackableFlag;
    private String activeFlag;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private Integer unitsRemaining;
    private Boolean isExpired;
    private String formattedAmount;
}
