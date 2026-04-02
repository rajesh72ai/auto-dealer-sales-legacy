package com.autosales.modules.registration.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecallCampaignRequest {

    @NotBlank @Size(max = 10)
    private String recallId;

    @Size(max = 12)
    private String nhtsaNum;

    @NotBlank @Size(max = 200)
    private String recallDesc;

    @NotBlank @Pattern(regexp = "[CHML]", message = "Severity must be C, H, M, or L")
    private String severity;

    @NotBlank @Size(max = 40)
    private String affectedYears;

    @NotBlank @Size(max = 100)
    private String affectedModels;

    @NotBlank @Size(max = 200)
    private String remedyDesc;

    private LocalDate remedyAvailDt;

    @NotNull
    private LocalDate announcedDate;
}
