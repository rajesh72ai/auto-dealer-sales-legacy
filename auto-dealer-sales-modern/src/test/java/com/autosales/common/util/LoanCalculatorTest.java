package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link LoanCalculator} — auto loan payment and amortization.
 */
class LoanCalculatorTest {

    private LoanCalculator calculator;

    @BeforeEach
    void setUp() {
        calculator = new LoanCalculator();
    }

    @Test
    void testStandardLoan() {
        // $30,000 at 5.5% for 60 months -> monthly payment ~$573.07
        LoanCalculationResult result = calculator.calculate(
                new BigDecimal("30000.00"),
                new BigDecimal("5.50"),
                60);

        BigDecimal expected = new BigDecimal("573.03");
        // Allow +/- $0.05 tolerance for rounding differences
        assertTrue(result.monthlyPayment().subtract(expected).abs()
                        .compareTo(new BigDecimal("0.05")) <= 0,
                "Expected monthly payment ~$573.03, got " + result.monthlyPayment());

        // Total of payments = monthlyPayment * 60
        assertEquals(0, result.totalOfPayments().compareTo(
                result.monthlyPayment().multiply(new BigDecimal("60"))));

        // Total interest should be positive
        assertTrue(result.totalInterest().signum() > 0);
    }

    @Test
    void testZeroPercentLoan() {
        // $24,000 at 0% for 48 months = $500.00/month exactly
        LoanCalculationResult result = calculator.calculate(
                new BigDecimal("24000.00"),
                BigDecimal.ZERO,
                48);

        assertEquals(0, new BigDecimal("500.00").compareTo(result.monthlyPayment()),
                "Expected $500.00/month for zero-interest loan");
        assertEquals(0, BigDecimal.ZERO.compareTo(result.totalInterest()),
                "Zero-interest loan should have zero total interest");
    }

    @Test
    void testShortTerm() {
        // $10,000 at 4% for 12 months
        LoanCalculationResult result = calculator.calculate(
                new BigDecimal("10000.00"),
                new BigDecimal("4.00"),
                12);

        // Total interest for a short-term loan at 4% should be reasonable (~$218)
        assertTrue(result.totalInterest().compareTo(new BigDecimal("100")) > 0,
                "Interest should be > $100");
        assertTrue(result.totalInterest().compareTo(new BigDecimal("400")) < 0,
                "Interest should be < $400");

        // Monthly payment should be slightly above $833.33 (10000/12)
        assertTrue(result.monthlyPayment().compareTo(new BigDecimal("833.33")) > 0);
    }

    @Test
    void testHighRate() {
        // $5,000 at 20% for 12 months
        LoanCalculationResult result = calculator.calculate(
                new BigDecimal("5000.00"),
                new BigDecimal("20.00"),
                12);

        // At 20% APR, monthly payment should be noticeably higher than principal/term
        BigDecimal simplePayment = new BigDecimal("5000.00").divide(new BigDecimal("12"), 2, java.math.RoundingMode.HALF_UP);
        assertTrue(result.monthlyPayment().compareTo(simplePayment) > 0,
                "High-rate payment should exceed simple division");
        assertTrue(result.totalInterest().compareTo(new BigDecimal("500")) > 0,
                "20% APR should generate significant interest");
    }

    @Test
    void testAmortizationSchedule() {
        // $20,000 at 6% for 60 months
        LoanCalculationResult result = calculator.calculate(
                new BigDecimal("20000.00"),
                new BigDecimal("6.00"),
                60);

        assertFalse(result.amortizationSchedule().isEmpty());
        assertTrue(result.amortizationSchedule().size() <= 12,
                "Schedule should be at most 12 entries");

        AmortizationEntry first = result.amortizationSchedule().get(0);
        assertEquals(1, first.month());

        // First month: interest + principal = payment
        BigDecimal sumParts = first.principalPortion().add(first.interestPortion());
        assertEquals(0, sumParts.compareTo(first.payment()),
                "Interest + principal should equal the monthly payment");

        // First month interest: $20,000 * (6%/12) = $100.00
        assertEquals(0, new BigDecimal("100.00").compareTo(first.interestPortion()),
                "First month interest should be $100.00");

        // Balance should decrease after first month
        assertTrue(first.remainingBalance().compareTo(new BigDecimal("20000.00")) < 0,
                "Remaining balance should be less than principal after first payment");
    }

    @Test
    void testValidationRejectsInvalid() {
        // Principal too low (< $500)
        assertThrows(IllegalArgumentException.class, () ->
                calculator.calculate(new BigDecimal("100.00"), new BigDecimal("5.00"), 12));

        // Rate too high (> 30%)
        assertThrows(IllegalArgumentException.class, () ->
                calculator.calculate(new BigDecimal("10000.00"), new BigDecimal("35.00"), 12));

        // Term too long (> 84)
        assertThrows(IllegalArgumentException.class, () ->
                calculator.calculate(new BigDecimal("10000.00"), new BigDecimal("5.00"), 120));

        // Term too short (< 6)
        assertThrows(IllegalArgumentException.class, () ->
                calculator.calculate(new BigDecimal("10000.00"), new BigDecimal("5.00"), 3));
    }
}
