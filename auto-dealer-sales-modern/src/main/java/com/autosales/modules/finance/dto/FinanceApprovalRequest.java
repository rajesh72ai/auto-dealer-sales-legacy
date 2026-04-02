package com.autosales.modules.finance.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for finance application approval, conditional approval, or decline.
 * Port of FINAPV00.cbl — finance approval/decision transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceApprovalRequest {

    @NotBlank(message = "Finance ID is required")
    @Size(max = 10)
    private String financeId;

    @NotBlank(message = "Action is required")
    @Pattern(regexp = "AP|CD|DN", message = "Action must be AP (Approved), CD (Conditional), or DN (Declined)")
    private String action;

    @Positive(message = "Approved amount must be positive")
    private BigDecimal amountApproved;

    @DecimalMin(value = "0", message = "Approved APR must be at least 0")
    @DecimalMax(value = "30", message = "Approved APR cannot exceed 30%")
    private BigDecimal aprApproved;

    @Size(max = 200, message = "Stipulations cannot exceed 200 characters")
    private String stipulations;
}
