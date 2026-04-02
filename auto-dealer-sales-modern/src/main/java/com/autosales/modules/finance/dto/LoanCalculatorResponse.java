package com.autosales.modules.finance.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Loan calculation response with payment breakdown, term comparisons, and amortization.
 * Port of FINCAL00.cbl — finance loan calculator result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoanCalculatorResponse {

    // --- Input echo ---
    private BigDecimal principal;
    private BigDecimal downPayment;
    private BigDecimal netPrincipal;
    private BigDecimal apr;
    private Integer termMonths;

    // --- Calculated totals ---
    private BigDecimal monthlyPayment;
    private BigDecimal totalOfPayments;
    private BigDecimal totalInterest;

    // --- Term comparisons (36/48/60/72 months) ---
    private List<TermComparison> comparisons;

    // --- Amortization schedule (first 12 months) ---
    private List<AmortizationEntry> amortizationSchedule;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TermComparison {
        private Integer term;
        private BigDecimal monthlyPayment;
        private BigDecimal totalPayments;
        private BigDecimal totalInterest;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AmortizationEntry {
        private Integer month;
        private BigDecimal payment;
        private BigDecimal principal;
        private BigDecimal interest;
        private BigDecimal cumulativeInterest;
        private BigDecimal balance;
    }
}
