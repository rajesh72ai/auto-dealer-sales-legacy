package com.autosales.modules.customer.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeadRequest {

    @NotNull
    private Integer customerId;

    @NotBlank @Size(max = 5)
    private String dealerCode;

    @NotBlank @Size(max = 3)
    private String leadSource;

    @Size(max = 6)
    private String interestModel;

    private Short interestYear;

    @NotBlank @Size(max = 8)
    private String assignedSales;

    private LocalDate followUpDate;

    @Size(max = 200)
    private String notes;

    // For status updates only
    @Pattern(regexp = "NW|CT|QF|PR|WN|LS|DD", message = "Lead status must be NW, CT, QF, PR, WN, LS, or DD")
    private String leadStatus;
}
