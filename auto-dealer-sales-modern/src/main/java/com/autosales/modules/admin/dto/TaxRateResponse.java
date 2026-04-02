package com.autosales.modules.admin.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaxRateResponse {

    private String stateCode;
    private String countyCode;
    private String cityCode;
    private BigDecimal stateRate;
    private BigDecimal countyRate;
    private BigDecimal cityRate;
    private BigDecimal docFeeMax;
    private BigDecimal titleFee;
    private BigDecimal regFee;
    private LocalDate effectiveDate;
    private LocalDate expiryDate;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private BigDecimal combinedRate;
    private String combinedPct;
    private BigDecimal testTaxOn30K;
}
