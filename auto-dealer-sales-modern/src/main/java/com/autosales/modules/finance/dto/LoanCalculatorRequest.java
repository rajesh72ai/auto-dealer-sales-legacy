package com.autosales.modules.finance.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for loan payment calculation with optional down payment.
 * Port of FINCAL00.cbl — finance loan calculator transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoanCalculatorRequest {

    @NotNull(message = "Principal amount is required")
    @DecimalMin(value = "500", message = "Principal must be at least $500")
    private BigDecimal principal;

    @NotNull(message = "APR is required")
    @DecimalMin(value = "0", message = "APR must be at least 0")
    @DecimalMax(value = "30", message = "APR cannot exceed 30%")
    private BigDecimal apr;

    @Builder.Default
    private Integer termMonths = 60;

    @Builder.Default
    private BigDecimal downPayment = BigDecimal.ZERO;
}
