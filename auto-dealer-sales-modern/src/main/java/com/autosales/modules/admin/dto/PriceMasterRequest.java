package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceMasterRequest {

    @NotNull @Min(1990) @Max(2030)
    private Short modelYear;

    @NotBlank @Size(max = 3)
    private String makeCode;

    @NotBlank @Size(max = 6)
    private String modelCode;

    @NotNull @Positive
    private BigDecimal msrp;

    @NotNull @Positive
    private BigDecimal invoicePrice;

    @NotNull
    private BigDecimal holdbackAmt;

    @NotNull
    private BigDecimal holdbackPct;

    @NotNull
    private BigDecimal destinationFee;

    @NotNull
    private BigDecimal advertisingFee;

    @NotNull
    private LocalDate effectiveDate;

    private LocalDate expiryDate;
}
