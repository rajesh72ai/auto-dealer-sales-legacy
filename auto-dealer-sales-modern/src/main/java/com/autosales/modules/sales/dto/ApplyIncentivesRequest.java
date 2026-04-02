package com.autosales.modules.sales.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.util.List;

/**
 * Request DTO for applying incentive programs to a deal.
 * Port of SLSINC00.cbl — incentive application transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplyIncentivesRequest {

    @NotEmpty(message = "At least one incentive ID is required")
    @Size(max = 5, message = "Cannot apply more than 5 incentives per request")
    private List<@NotBlank String> incentiveIds;
}
