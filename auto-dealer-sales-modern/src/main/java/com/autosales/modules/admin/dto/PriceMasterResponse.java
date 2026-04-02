package com.autosales.modules.admin.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceMasterResponse {

    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private BigDecimal msrp;
    private BigDecimal invoicePrice;
    private BigDecimal holdbackAmt;
    private BigDecimal holdbackPct;
    private BigDecimal destinationFee;
    private BigDecimal advertisingFee;
    private LocalDate effectiveDate;
    private LocalDate expiryDate;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private BigDecimal dealerMargin;
    private String formattedMsrp;
    private String formattedInvoice;
}
