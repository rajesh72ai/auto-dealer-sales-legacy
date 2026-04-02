package com.autosales.modules.sales.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Request DTO for completing/delivering a deal.
 * Port of SLSDLV00.cbl — deal delivery/completion transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompletionRequest {

    private LocalDate deliveryDate;         // defaults to today if not provided

    private BigDecimal downPayment;         // optional override of existing down payment

    private boolean insuranceVerified;

    private boolean tradeTitleReceived;
}
