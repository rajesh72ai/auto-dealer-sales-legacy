package com.autosales.modules.finance.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for submitting a finance application on a deal.
 * Port of FINSUB00.cbl — finance application submission transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceAppRequest {

    @NotBlank(message = "Deal number is required")
    @Size(max = 10)
    private String dealNumber;

    @NotBlank(message = "Finance type is required")
    @Pattern(regexp = "L|S|C", message = "Finance type must be L (Loan), S (Lease), or C (Cash)")
    private String financeType;

    @Size(max = 5)
    private String lenderCode;

    @NotNull(message = "Amount requested is required")
    @Positive(message = "Amount requested must be positive")
    private BigDecimal amountRequested;

    @DecimalMin(value = "0", message = "APR must be at least 0")
    @DecimalMax(value = "30", message = "APR cannot exceed 30%")
    private BigDecimal aprRequested;

    @Min(value = 12, message = "Term must be at least 12 months")
    @Max(value = 84, message = "Term cannot exceed 84 months")
    private Short termMonths;

    @DecimalMin(value = "0", message = "Down payment cannot be negative")
    private BigDecimal downPayment;
}
