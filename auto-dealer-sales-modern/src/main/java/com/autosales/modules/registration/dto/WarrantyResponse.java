package com.autosales.modules.registration.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WarrantyResponse {

    private Integer warrantyId;
    private String vin;
    private String dealNumber;
    private String warrantyType;
    private LocalDate startDate;
    private LocalDate expiryDate;
    private Integer mileageLimit;
    private BigDecimal deductible;
    private String activeFlag;
    private LocalDateTime registeredTs;

    // Computed fields
    private String warrantyTypeName;
    private String formattedDeductible;
    private String status;
    private Long remainingDays;
}
