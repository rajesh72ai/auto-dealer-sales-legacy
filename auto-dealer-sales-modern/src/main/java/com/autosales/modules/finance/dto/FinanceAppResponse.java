package com.autosales.modules.finance.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Full finance application response with entity fields and computed display values.
 * Port of FININQ00.cbl — finance application inquiry transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceAppResponse {

    // --- Entity fields ---
    private String financeId;
    private String dealNumber;
    private Integer customerId;
    private String financeType;
    private String lenderCode;
    private String lenderName;
    private String appStatus;
    private BigDecimal amountRequested;
    private BigDecimal amountApproved;
    private BigDecimal aprRequested;
    private BigDecimal aprApproved;
    private Short termMonths;
    private BigDecimal monthlyPayment;
    private BigDecimal downPayment;
    private String creditTier;
    private String stipulations;
    private LocalDateTime submittedTs;
    private LocalDateTime decisionTs;
    private LocalDateTime fundedTs;

    // --- Computed display fields ---
    private String financeTypeName;     // Loan, Lease, Cash
    private String statusName;          // New, Approved, Conditional, Declined
    private BigDecimal totalOfPayments; // monthlyPayment * termMonths
    private BigDecimal totalInterest;   // totalOfPayments - amountFinanced
}
