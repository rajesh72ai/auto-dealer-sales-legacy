package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IncentiveProgramRequest {

    @NotBlank @Size(max = 10)
    private String incentiveId;

    @NotBlank @Size(max = 60)
    private String incentiveName;

    @NotBlank @Pattern(regexp = "CR|DR|LR|FR|LB")
    private String incentiveType;

    private Short modelYear;

    @Size(max = 3)
    private String makeCode;

    @Size(max = 6)
    private String modelCode;

    @Size(max = 3)
    private String regionCode;

    @NotNull @DecimalMin("0")
    private BigDecimal amount;

    private BigDecimal rateOverride;

    @NotNull
    private LocalDate startDate;

    @NotNull
    private LocalDate endDate;

    private Integer maxUnits;

    @NotBlank @Pattern(regexp = "[YN]")
    private String stackableFlag;

    @NotBlank @Pattern(regexp = "[YN]")
    private String activeFlag;
}
