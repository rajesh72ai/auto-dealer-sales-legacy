package com.autosales.modules.finance.dto;

import lombok.*;

import java.math.BigDecimal;

/**
 * Lease calculation response with full monthly payment breakdown.
 * Port of FINLSE00.cbl — finance lease calculator result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaseCalculatorResponse {

    // --- Input echo ---
    private BigDecimal capitalizedCost;
    private BigDecimal capCostReduction;
    private BigDecimal residualPct;
    private BigDecimal moneyFactor;
    private Integer termMonths;
    private BigDecimal taxRate;
    private BigDecimal acqFee;
    private BigDecimal securityDeposit;

    // --- Calculated breakdown ---
    private BigDecimal adjustedCapCost;
    private BigDecimal residualAmount;
    private BigDecimal monthlyDepreciation;
    private BigDecimal monthlyFinanceCharge;
    private BigDecimal monthlyTax;
    private BigDecimal totalMonthlyPayment;
    private BigDecimal equivalentApr;

    // --- Totals ---
    private BigDecimal driveOffAmount;
    private BigDecimal totalOfPayments;
    private BigDecimal totalInterestEquivalent;
}
