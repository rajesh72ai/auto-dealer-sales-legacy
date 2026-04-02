package com.autosales.modules.finance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "lease_terms")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeaseTerms {

    @Id
    @Column(name = "finance_id")
    private String financeId;

    @Column(name = "residual_pct", nullable = false)
    private BigDecimal residualPct;

    @Column(name = "residual_amt", nullable = false)
    private BigDecimal residualAmt;

    @Column(name = "money_factor", nullable = false)
    private BigDecimal moneyFactor;

    @Column(name = "capitalized_cost", nullable = false)
    private BigDecimal capitalizedCost;

    @Column(name = "cap_cost_reduce", nullable = false)
    private BigDecimal capCostReduce;

    @Column(name = "adj_cap_cost", nullable = false)
    private BigDecimal adjCapCost;

    @Column(name = "depreciation_amt", nullable = false)
    private BigDecimal depreciationAmt;

    @Column(name = "finance_charge", nullable = false)
    private BigDecimal financeCharge;

    @Column(name = "monthly_tax", nullable = false)
    private BigDecimal monthlyTax;

    @Column(name = "miles_per_year", nullable = false)
    private Integer milesPerYear;

    @Column(name = "excess_mile_chg", nullable = false)
    private BigDecimal excessMileChg;

    @Column(name = "disposition_fee", nullable = false)
    private BigDecimal dispositionFee;

    @Column(name = "acq_fee", nullable = false)
    private BigDecimal acqFee;

    @Column(name = "security_deposit", nullable = false)
    private BigDecimal securityDeposit;
}
