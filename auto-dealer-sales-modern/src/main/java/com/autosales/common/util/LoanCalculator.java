package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Auto loan payment and amortization calculator.
 * Port of COMLONL0.cbl — standard amortization formula with
 * monthly schedule generation.
 *
 * <p>All monetary amounts use BigDecimal with scale 2 and RoundingMode.HALF_UP.
 * The amortization schedule is generated for the first 12 months
 * (or full term if term &lt; 12).</p>
 */
@Component
public class LoanCalculator {

    private static final int MONEY_SCALE = 2;
    private static final int RATE_SCALE = 10;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;
    private static final MathContext MC = new MathContext(15, ROUNDING);

    private static final BigDecimal MIN_PRINCIPAL = new BigDecimal("500.00");
    private static final BigDecimal MAX_PRINCIPAL = new BigDecimal("999999.99");
    private static final BigDecimal MAX_RATE = new BigDecimal("30.00");
    private static final int MIN_TERM = 6;
    private static final int MAX_TERM = 84;
    private static final BigDecimal TWELVE = new BigDecimal("12");
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    /**
     * Calculate monthly payment, total interest, and amortization schedule.
     *
     * @param principal  loan principal amount ($500 - $999,999.99)
     * @param annualRate annual interest rate as a percentage (0 - 30%)
     * @param termMonths loan term in months (6 - 84)
     * @return loan calculation result with amortization schedule
     * @throws IllegalArgumentException if parameters are outside valid ranges
     */
    public LoanCalculationResult calculate(BigDecimal principal, BigDecimal annualRate, int termMonths) {
        // Validate inputs
        validateInputs(principal, annualRate, termMonths);

        BigDecimal monthlyPayment;
        BigDecimal monthlyRate;

        if (annualRate.signum() == 0) {
            // Zero-interest loan
            monthlyRate = BigDecimal.ZERO;
            monthlyPayment = principal.divide(new BigDecimal(termMonths), MONEY_SCALE, ROUNDING);
        } else {
            // monthlyRate = annualRate / 12 / 100
            monthlyRate = annualRate.divide(TWELVE, RATE_SCALE, ROUNDING)
                    .divide(HUNDRED, RATE_SCALE, ROUNDING);

            // payment = P * [r(1+r)^n] / [(1+r)^n - 1]
            BigDecimal onePlusR = BigDecimal.ONE.add(monthlyRate);
            BigDecimal onePlusRPowN = power(onePlusR, termMonths);

            BigDecimal numerator = principal.multiply(monthlyRate.multiply(onePlusRPowN, MC), MC);
            BigDecimal denominator = onePlusRPowN.subtract(BigDecimal.ONE);

            monthlyPayment = numerator.divide(denominator, MONEY_SCALE, ROUNDING);
        }

        // Total of all payments
        BigDecimal totalOfPayments = monthlyPayment.multiply(new BigDecimal(termMonths))
                .setScale(MONEY_SCALE, ROUNDING);

        // Total interest
        BigDecimal totalInterest = totalOfPayments.subtract(principal)
                .setScale(MONEY_SCALE, ROUNDING);

        // Generate amortization schedule (first 12 months or full term)
        int scheduleMonths = Math.min(termMonths, 12);
        List<AmortizationEntry> schedule = new ArrayList<>(scheduleMonths);

        BigDecimal balance = principal.setScale(MONEY_SCALE, ROUNDING);
        BigDecimal cumulativeInterest = BigDecimal.ZERO.setScale(MONEY_SCALE, ROUNDING);

        for (int month = 1; month <= scheduleMonths; month++) {
            BigDecimal interestPortion = balance.multiply(monthlyRate)
                    .setScale(MONEY_SCALE, ROUNDING);
            BigDecimal principalPortion = monthlyPayment.subtract(interestPortion)
                    .setScale(MONEY_SCALE, ROUNDING);

            // Adjust last payment to clear balance exactly
            if (month == termMonths) {
                principalPortion = balance;
                BigDecimal actualPayment = principalPortion.add(interestPortion);
                cumulativeInterest = cumulativeInterest.add(interestPortion);
                balance = BigDecimal.ZERO.setScale(MONEY_SCALE, ROUNDING);
                schedule.add(new AmortizationEntry(
                        month, actualPayment.setScale(MONEY_SCALE, ROUNDING),
                        principalPortion, interestPortion,
                        cumulativeInterest, balance));
                break;
            }

            balance = balance.subtract(principalPortion).setScale(MONEY_SCALE, ROUNDING);
            cumulativeInterest = cumulativeInterest.add(interestPortion);

            schedule.add(new AmortizationEntry(
                    month, monthlyPayment, principalPortion, interestPortion,
                    cumulativeInterest, balance));
        }

        return new LoanCalculationResult(monthlyPayment, totalInterest, totalOfPayments, schedule);
    }

    private void validateInputs(BigDecimal principal, BigDecimal annualRate, int termMonths) {
        if (principal == null) {
            throw new IllegalArgumentException("Principal must not be null");
        }
        if (principal.compareTo(MIN_PRINCIPAL) < 0 || principal.compareTo(MAX_PRINCIPAL) > 0) {
            throw new IllegalArgumentException(
                    "Principal must be between $500.00 and $999,999.99, got " + principal);
        }
        if (annualRate == null) {
            throw new IllegalArgumentException("Annual rate must not be null");
        }
        if (annualRate.signum() < 0 || annualRate.compareTo(MAX_RATE) > 0) {
            throw new IllegalArgumentException(
                    "Annual rate must be between 0% and 30%, got " + annualRate);
        }
        if (termMonths < MIN_TERM || termMonths > MAX_TERM) {
            throw new IllegalArgumentException(
                    "Term must be between 6 and 84 months, got " + termMonths);
        }
    }

    /**
     * Raise a BigDecimal base to an integer exponent using repeated multiplication.
     */
    private BigDecimal power(BigDecimal base, int exponent) {
        BigDecimal result = BigDecimal.ONE;
        for (int i = 0; i < exponent; i++) {
            result = result.multiply(base, MC);
        }
        return result;
    }
}
