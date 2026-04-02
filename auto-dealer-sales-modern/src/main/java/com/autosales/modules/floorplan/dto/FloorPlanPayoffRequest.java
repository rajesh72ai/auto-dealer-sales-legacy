package com.autosales.modules.floorplan.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Request DTO for floor plan vehicle payoff.
 * Port of FPPAY00.cbl — floor plan payoff transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanPayoffRequest {

    @NotBlank(message = "VIN is required")
    @Size(min = 17, max = 17, message = "VIN must be exactly 17 characters")
    private String vin;
}
