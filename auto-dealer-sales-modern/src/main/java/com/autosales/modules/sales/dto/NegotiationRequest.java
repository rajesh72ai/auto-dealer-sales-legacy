package com.autosales.modules.sales.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Request DTO for deal negotiation (counter-offer or discount).
 * Port of SLSDESK0.cbl — sales desk / desking transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NegotiationRequest {

    @NotBlank(message = "Deal number is required")
    private String dealNumber;

    @NotBlank(message = "Action is required")
    @Pattern(regexp = "CO|DS", message = "Action must be CO (Counter Offer) or DS (Discount)")
    private String action;

    @DecimalMin(value = "0.00", message = "Amount must be non-negative")
    private BigDecimal amount;

    @DecimalMin(value = "0.00", message = "Discount percentage must be non-negative")
    @DecimalMax(value = "100.00", message = "Discount percentage cannot exceed 100")
    private BigDecimal discountPct;

    @Size(max = 200, message = "Desk notes cannot exceed 200 characters")
    private String deskNotes;
}
