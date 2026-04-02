package com.autosales.modules.registration.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegistrationStatusUpdateRequest {

    @NotBlank @Pattern(regexp = "PG|IS|RJ|ER", message = "Status must be PG, IS, RJ, or ER")
    private String newStatus;

    @Size(max = 10)
    private String plateNumber;

    @Size(max = 20)
    private String titleNumber;

    @Size(max = 60)
    private String statusDesc;
}
