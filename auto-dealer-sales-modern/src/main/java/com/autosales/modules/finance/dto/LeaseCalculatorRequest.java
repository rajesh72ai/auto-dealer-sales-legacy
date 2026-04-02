package com.autosales.modules.finance.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for lease payment calculation with full lease structure inputs.
 * Port of FINLSE00.cbl — finance lease calculator transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaseCalculatorRequest {

    @Size(max = 10)
    private String dealNumber;

    @NotNull(message = "Capitalized cost is required")
    @Positive(message = "Capitalized cost must be positive")
    private BigDecimal capitalizedCost;

    @Builder.Default
    private BigDecimal capCostReduction = BigDecimal.ZERO;

    @Builder.Default
    private BigDecimal residualPct = new BigDecimal("55.00");

    @Builder.Default
    private BigDecimal moneyFactor = new BigDecimal("0.00125");

    @Builder.Default
    private Integer termMonths = 36;

    @Builder.Default
    private BigDecimal taxRate = new BigDecimal("7.0");

    @Builder.Default
    private BigDecimal acqFee = new BigDecimal("695");

    @Builder.Default
    private BigDecimal securityDeposit = BigDecimal.ZERO;
}
