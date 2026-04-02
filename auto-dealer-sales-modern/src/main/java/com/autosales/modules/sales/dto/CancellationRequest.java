package com.autosales.modules.sales.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Request DTO for cancelling or unwinding a deal.
 * Port of SLSCAN00.cbl — deal cancellation transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CancellationRequest {

    @NotBlank(message = "Cancellation reason is required")
    @Size(max = 200, message = "Reason cannot exceed 200 characters")
    private String reason;
}
