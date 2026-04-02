package com.autosales.modules.finance.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Finance approval result response with original vs approved terms comparison.
 * Port of FINAPV00.cbl — finance approval result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceApprovalResponse {

    private String financeId;
    private String dealNumber;
    private String action;
    private String actionName;          // Approved, Conditional, Declined

    // --- Original terms ---
    private BigDecimal originalAmount;
    private BigDecimal originalApr;
    private Short originalTerm;

    // --- Approved terms ---
    private BigDecimal approvedAmount;
    private BigDecimal approvedApr;

    // --- Calculated payment details ---
    private BigDecimal monthlyPayment;
    private BigDecimal totalOfPayments;
    private BigDecimal totalInterest;

    private String stipulations;
    private LocalDateTime decisionTs;
    private String newStatus;
}
