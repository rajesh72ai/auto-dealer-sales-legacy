package com.autosales.modules.sales.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for adding a trade-in vehicle to a deal.
 * Port of SLSTRD00.cbl — trade-in appraisal entry transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeInRequest {

    @Size(max = 17, message = "Trade VIN cannot exceed 17 characters")
    private String vin;

    @NotNull(message = "Trade year is required")
    private Short tradeYear;

    @NotBlank(message = "Trade make is required")
    @Size(max = 20)
    private String tradeMake;

    @NotBlank(message = "Trade model is required")
    @Size(max = 30)
    private String tradeModel;

    @Size(max = 15)
    private String tradeColor;

    @NotNull(message = "Odometer is required")
    @Min(value = 0, message = "Odometer must be non-negative")
    private Integer odometer;

    @NotBlank(message = "Condition code is required")
    @Pattern(regexp = "[EGFP]", message = "Condition must be E (Excellent), G (Good), F (Fair), or P (Poor)")
    private String conditionCode;

    @DecimalMin(value = "0.00", message = "Over-allowance must be non-negative")
    private BigDecimal overAllow;

    @DecimalMin(value = "0.00", message = "Payoff amount must be non-negative")
    private BigDecimal payoffAmt;

    @Size(max = 40)
    private String payoffBank;

    @Size(max = 20)
    private String payoffAcct;

    @NotBlank(message = "Appraised-by ID is required")
    @Size(max = 8)
    private String appraisedBy;
}
