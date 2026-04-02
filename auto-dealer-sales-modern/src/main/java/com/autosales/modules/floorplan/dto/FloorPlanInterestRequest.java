package com.autosales.modules.floorplan.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Request DTO for floor plan interest accrual — single vehicle or batch by dealer.
 * Port of FPINT00.cbl — floor plan interest calculation transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanInterestRequest {

    @NotBlank(message = "Mode is required")
    @Pattern(regexp = "SINGLE|BATCH", message = "Mode must be SINGLE or BATCH")
    private String mode;

    @Size(min = 17, max = 17, message = "VIN must be exactly 17 characters")
    private String vin;

    @Size(max = 5)
    private String dealerCode;
}
