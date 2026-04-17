package com.autosales.modules.finance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "finance_app")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FinanceApp {

    @Id
    @Column(name = "finance_id", length = 12)
    private String financeId;

    @Column(name = "deal_number", nullable = false)
    private String dealNumber;

    @Column(name = "customer_id", nullable = false)
    private Integer customerId;

    @Column(name = "finance_type", nullable = false)
    private String financeType;

    @Column(name = "lender_code")
    private String lenderCode;

    @Column(name = "lender_name")
    private String lenderName;

    @Column(name = "app_status", nullable = false)
    private String appStatus;

    @Column(name = "amount_requested", nullable = false)
    private BigDecimal amountRequested;

    @Column(name = "amount_approved")
    private BigDecimal amountApproved;

    @Column(name = "apr_requested")
    private BigDecimal aprRequested;

    @Column(name = "apr_approved")
    private BigDecimal aprApproved;

    @Column(name = "term_months")
    private Short termMonths;

    @Column(name = "monthly_payment")
    private BigDecimal monthlyPayment;

    @Column(name = "down_payment", nullable = false)
    private BigDecimal downPayment;

    @Column(name = "credit_tier")
    private String creditTier;

    @Column(name = "stipulations")
    private String stipulations;

    @Column(name = "submitted_ts")
    private LocalDateTime submittedTs;

    @Column(name = "decision_ts")
    private LocalDateTime decisionTs;

    @Column(name = "funded_ts")
    private LocalDateTime fundedTs;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
