package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaxRateRequest {

    @NotBlank @Size(min = 2, max = 2)
    private String stateCode;

    @NotBlank @Size(max = 5)
    private String countyCode;

    @NotBlank @Size(max = 5)
    private String cityCode;

    @NotNull @DecimalMin("0") @DecimalMax("0.15")
    private BigDecimal stateRate;

    @NotNull @DecimalMin("0") @DecimalMax("0.15")
    private BigDecimal countyRate;

    @NotNull @DecimalMin("0") @DecimalMax("0.15")
    private BigDecimal cityRate;

    @NotNull
    private BigDecimal docFeeMax;

    @NotNull
    private BigDecimal titleFee;

    @NotNull
    private BigDecimal regFee;

    @NotNull
    private LocalDate effectiveDate;

    private LocalDate expiryDate;
}
