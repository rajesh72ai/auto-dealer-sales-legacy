package com.autosales.modules.floorplan.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Request DTO for adding a vehicle to floor plan financing.
 * Port of FPADD00.cbl — floor plan add vehicle transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanAddRequest {

    @NotBlank(message = "VIN is required")
    @Size(min = 17, max = 17, message = "VIN must be exactly 17 characters")
    private String vin;

    @NotBlank(message = "Lender ID is required")
    @Size(max = 5)
    private String lenderId;

    @NotBlank(message = "Dealer code is required")
    @Size(max = 5)
    private String dealerCode;

    @Positive(message = "Invoice amount must be positive")
    private BigDecimal invoiceAmount;

    private LocalDate floorDate;
}
