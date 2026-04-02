package com.autosales.modules.customer.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreditCheckResponse {

    private Integer creditId;
    private Integer customerId;
    private String customerName;
    private BigDecimal annualIncome;
    private BigDecimal monthlyIncome;
    private String creditTier;
    private String creditTierDesc;
    private Short creditScore;
    private String bureauCode;
    private BigDecimal dtiRatio;
    private BigDecimal monthlyDebt;
    private BigDecimal maxFinancing;
    private LocalDate expiryDate;
    private String status;
    private String message;
}
