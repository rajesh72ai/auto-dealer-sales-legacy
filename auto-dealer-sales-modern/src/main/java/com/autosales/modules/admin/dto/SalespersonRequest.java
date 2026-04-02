package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SalespersonRequest {

    @NotBlank @Size(max = 8)
    private String salespersonId;

    @NotBlank @Size(max = 30)
    private String salespersonName;

    @NotBlank @Size(max = 5)
    private String dealerCode;

    private LocalDate hireDate;

    private LocalDate terminationDate;

    @NotBlank @Pattern(regexp = "ST|SR|MG|TR")
    private String commissionPlan;

    @NotBlank @Pattern(regexp = "[YN]")
    private String activeFlag;
}
