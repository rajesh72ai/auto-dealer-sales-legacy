package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaxCalculationRequest {

    @NotNull @Positive
    private BigDecimal taxableAmount;

    private BigDecimal tradeAllowance;

    @NotBlank
    private String stateCode;

    @NotBlank
    private String countyCode;

    @NotBlank
    private String cityCode;
}
