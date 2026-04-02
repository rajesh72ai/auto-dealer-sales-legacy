package com.autosales.modules.finance.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.util.List;

/**
 * Request DTO for selecting F&I products on a deal.
 * Port of FINPRD00.cbl — F&I product selection transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceProductRequest {

    @NotBlank(message = "Deal number is required")
    @Size(max = 10)
    private String dealNumber;

    @NotNull(message = "Selected products list is required")
    private List<String> selectedProducts;
}
