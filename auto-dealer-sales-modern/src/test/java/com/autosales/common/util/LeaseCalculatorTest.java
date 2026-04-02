package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link LeaseCalculator} — vehicle lease payment calculation.
 */
class LeaseCalculatorTest {

    private LeaseCalculator calculator;

    @BeforeEach
    void setUp() {
        calculator = new LeaseCalculator();
    }

    @Test
    void testStandardLease() {
        // $40,000 vehicle, 55% residual, 0.00125 money factor, 36 months, 0 tax, 0 fees
        LeaseCalculationResult result = calculator.calculate(
                new BigDecimal("40000.00"),   // capitalized cost
                BigDecimal.ZERO,               // cap cost reduction (no down)
                new BigDecimal("55.00"),        // residual %
                new BigDecimal("0.00125"),      // money factor
                36,                             // term
                BigDecimal.ZERO,                // tax rate
                BigDecimal.ZERO,                // acquisition fee
                BigDecimal.ZERO);               // security deposit

        // Residual = 40000 * 55% = $22,000.00
        assertEquals(0, new BigDecimal("22000.00").compareTo(result.residualAmount()),
                "Residual should be $22,000");

        // adjCapCost = 40000 + 0 - 0 = 40000
        assertEquals(0, new BigDecimal("40000.00").compareTo(result.adjustedCapCost()));

        // Monthly depreciation = (40000 - 22000) / 36 = $500.00
        assertEquals(0, new BigDecimal("500.00").compareTo(result.monthlyDepreciation()),
                "Monthly depreciation should be $500.00");

        // Monthly finance charge = (40000 + 22000) * 0.00125 = $77.50
        assertEquals(0, new BigDecimal("77.50").compareTo(result.monthlyFinanceCharge()),
                "Monthly finance charge should be $77.50");

        // Total monthly = 500 + 77.50 = $577.50
        assertEquals(0, new BigDecimal("577.50").compareTo(result.totalMonthlyPayment()));
    }

    @Test
    void testNoCapReduction() {
        // Zero down payment — adjCapCost equals capitalizedCost + acqFee
        LeaseCalculationResult result = calculator.calculate(
                new BigDecimal("35000.00"),
                BigDecimal.ZERO,                // no down payment
                new BigDecimal("50.00"),
                new BigDecimal("0.00100"),
                36,
                BigDecimal.ZERO,
                new BigDecimal("695.00"),        // acquisition fee
                BigDecimal.ZERO);

        // adjCapCost = 35000 + 695 - 0 = 35695
        assertEquals(0, new BigDecimal("35695.00").compareTo(result.adjustedCapCost()),
                "Adjusted cap cost should include acq fee");

        // Residual = 35000 * 50% = 17500
        assertEquals(0, new BigDecimal("17500.00").compareTo(result.residualAmount()));
    }

    @Test
    void testHighResidual() {
        // 70% residual means low depreciation, lower monthly
        LeaseCalculationResult result = calculator.calculate(
                new BigDecimal("50000.00"),
                BigDecimal.ZERO,
                new BigDecimal("70.00"),         // 70% residual
                new BigDecimal("0.00100"),
                36,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO);

        // Residual = 50000 * 70% = $35,000
        assertEquals(0, new BigDecimal("35000.00").compareTo(result.residualAmount()));

        // Monthly depreciation = (50000 - 35000) / 36 = $416.67
        assertEquals(0, new BigDecimal("416.67").compareTo(result.monthlyDepreciation()),
                "High residual should yield lower depreciation");
    }

    @Test
    void testMoneyFactorToApr() {
        // equivalentApr = moneyFactor * 2400
        // 0.00125 * 2400 = 3.00
        LeaseCalculationResult result = calculator.calculate(
                new BigDecimal("40000.00"),
                BigDecimal.ZERO,
                new BigDecimal("55.00"),
                new BigDecimal("0.00125"),
                36,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO);

        assertEquals(0, new BigDecimal("3.00").compareTo(result.equivalentApr()),
                "Money factor 0.00125 * 2400 should equal 3.00% APR");
    }

    @Test
    void testLeaseWithTax() {
        // Verify tax is applied to (depreciation + finance charge)
        LeaseCalculationResult result = calculator.calculate(
                new BigDecimal("40000.00"),
                BigDecimal.ZERO,
                new BigDecimal("55.00"),
                new BigDecimal("0.00125"),
                36,
                new BigDecimal("7.50"),          // 7.5% tax rate
                BigDecimal.ZERO,
                BigDecimal.ZERO);

        // From standard lease test: depreciation = $500, finance = $77.50
        // Monthly tax = (500 + 77.50) * 7.50 / 100 = $43.31 (rounded)
        BigDecimal expectedTax = new BigDecimal("43.31");
        assertTrue(result.monthlyTax().subtract(expectedTax).abs()
                        .compareTo(new BigDecimal("0.01")) <= 0,
                "Monthly tax should be ~$43.31, got " + result.monthlyTax());

        // Total monthly = 500 + 77.50 + 43.31 = $620.81
        BigDecimal expectedTotal = new BigDecimal("620.81");
        assertTrue(result.totalMonthlyPayment().subtract(expectedTotal).abs()
                        .compareTo(new BigDecimal("0.01")) <= 0,
                "Total monthly should be ~$620.81, got " + result.totalMonthlyPayment());
    }
}
