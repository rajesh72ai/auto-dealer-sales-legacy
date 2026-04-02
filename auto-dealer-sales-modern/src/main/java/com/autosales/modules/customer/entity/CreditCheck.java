package com.autosales.modules.customer.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "credit_check")
public class CreditCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "credit_id")
    private Integer creditId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Column(name = "bureau_code", nullable = false, length = 2)
    private String bureauCode;

    @Column(name = "credit_score")
    private Short creditScore;

    @Column(name = "credit_tier", length = 1)
    private String creditTier;

    @Column(name = "request_ts", nullable = false)
    private LocalDateTime requestTs;

    @Column(name = "response_ts")
    private LocalDateTime responseTs;

    @Column(name = "status", nullable = false, length = 2)
    private String status;

    @Column(name = "monthly_debt", precision = 9, scale = 2)
    private BigDecimal monthlyDebt;

    @Column(name = "monthly_income", precision = 9, scale = 2)
    private BigDecimal monthlyIncome;

    @Column(name = "dti_ratio", precision = 5, scale = 2)
    private BigDecimal dtiRatio;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;
}
