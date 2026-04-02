package com.autosales.modules.registration.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WarrantyClaimRequest {

    @NotBlank @Size(min = 17, max = 17)
    private String vin;

    @NotBlank @Size(max = 5)
    private String dealerCode;

    @NotBlank @Size(max = 2)
    private String claimType;

    @NotNull
    private LocalDate claimDate;

    private LocalDate repairDate;

    @NotNull @DecimalMin("0.00")
    private BigDecimal laborAmt;

    @NotNull @DecimalMin("0.00")
    private BigDecimal partsAmt;

    @Size(max = 8)
    private String technicianId;

    @Size(max = 12)
    private String repairOrderNum;

    @Size(max = 200)
    private String notes;

    @Pattern(regexp = "NW|IP|AP|PA|PD|DN|CL", message = "Invalid claim status")
    private String claimStatus;
}
