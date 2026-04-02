package com.autosales.modules.sales.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Full deal view response DTO with entity fields and computed display values.
 * Port of SLSINQ00.cbl — sales deal inquiry transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealResponse {

    // --- Entity fields ---
    private String dealNumber;
    private String dealerCode;
    private Integer customerId;
    private String vin;
    private String salespersonId;
    private String salesManagerId;
    private String dealType;
    private String dealStatus;
    private BigDecimal vehiclePrice;
    private BigDecimal totalOptions;
    private BigDecimal destinationFee;
    private BigDecimal subtotal;
    private BigDecimal tradeAllow;
    private BigDecimal tradePayoff;
    private BigDecimal netTrade;
    private BigDecimal rebatesApplied;
    private BigDecimal discountAmt;
    private BigDecimal docFee;
    private BigDecimal stateTax;
    private BigDecimal countyTax;
    private BigDecimal cityTax;
    private BigDecimal titleFee;
    private BigDecimal regFee;
    private BigDecimal totalPrice;
    private BigDecimal downPayment;
    private BigDecimal amountFinanced;
    private BigDecimal frontGross;
    private BigDecimal backGross;
    private BigDecimal totalGross;
    private LocalDate dealDate;
    private LocalDate deliveryDate;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // --- Computed / joined fields ---
    private String customerName;
    private String vehicleDesc;       // "2025 TOY CAMRY"
    private String salespersonName;

    // --- Formatted currency fields ---
    private String formattedVehiclePrice;
    private String formattedTotalPrice;
    private String formattedFrontGross;
    private String formattedDownPayment;
    private String formattedAmountFinanced;

    // --- Status description ---
    private String statusDescription;
}
