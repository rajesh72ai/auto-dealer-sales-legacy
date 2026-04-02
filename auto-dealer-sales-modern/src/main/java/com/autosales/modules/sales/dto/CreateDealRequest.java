package com.autosales.modules.sales.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for creating a new sales deal worksheet.
 * Port of SLSWKS00.cbl — sales worksheet entry transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateDealRequest {

    @NotNull(message = "Customer ID is required")
    private Integer customerId;

    @NotBlank(message = "VIN is required")
    @Size(max = 17)
    private String vin;

    @NotBlank(message = "Salesperson ID is required")
    @Size(max = 8)
    private String salespersonId;

    @NotBlank(message = "Deal type is required")
    @Pattern(regexp = "[RLFW]", message = "Deal type must be R (Retail), L (Lease), F (Fleet), or W (Wholesale)")
    private String dealType;

    @NotBlank(message = "Dealer code is required")
    @Size(max = 5)
    private String dealerCode;

    @DecimalMin(value = "0.00", message = "Down payment must be non-negative")
    private BigDecimal downPayment;
}
