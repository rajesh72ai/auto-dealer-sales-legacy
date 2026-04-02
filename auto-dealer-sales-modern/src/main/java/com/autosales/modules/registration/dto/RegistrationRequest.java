package com.autosales.modules.registration.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegistrationRequest {

    @NotBlank @Size(max = 10)
    private String dealNumber;

    @NotBlank @Size(min = 17, max = 17, message = "VIN must be exactly 17 characters")
    private String vin;

    @NotNull
    private Integer customerId;

    @NotBlank @Size(min = 2, max = 2)
    private String regState;

    @NotBlank @Pattern(regexp = "NW|TF|RN|DP", message = "Registration type must be NW, TF, RN, or DP")
    private String regType;

    @Size(max = 60)
    private String lienHolder;

    @Size(max = 100)
    private String lienHolderAddr;

    @DecimalMin("0.00")
    private BigDecimal regFeePaid;

    @DecimalMin("0.00")
    private BigDecimal titleFeePaid;
}
