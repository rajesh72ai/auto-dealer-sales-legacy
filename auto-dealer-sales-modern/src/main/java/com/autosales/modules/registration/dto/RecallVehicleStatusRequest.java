package com.autosales.modules.registration.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecallVehicleStatusRequest {

    @NotBlank @Pattern(regexp = "SC|IP|CM|NA", message = "Status must be SC, IP, CM, or NA")
    private String newStatus;

    private LocalDate scheduledDate;

    @Size(max = 8)
    private String technicianId;
}
