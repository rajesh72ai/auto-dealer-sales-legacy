package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link PricingEngine} — deal pricing and gross profit analysis.
 */
class PricingEngineTest {

    private PricingEngine engine;

    @BeforeEach
    void setUp() {
        engine = new PricingEngine();
    }

    @Test
    void testGrossCalculation() {
        // sellingPrice $35,000, invoice $30,000, holdback $900 (fixed amount)
        // frontGross = 35000 - 30000 = $5,000
        // backGross = holdback = $900
        // totalGross = 5000 + 900 = $5,900
        PricingResult result = engine.calculateDealPricing(
                new BigDecimal("37000.00"),   // msrp
                new BigDecimal("30000.00"),   // invoice
                new BigDecimal("35000.00"),   // selling price
                new BigDecimal("900.00"),     // holdback amount
                BigDecimal.ZERO,              // holdback pct (ignored when amt > 0)
                BigDecimal.ZERO,              // destination
                BigDecimal.ZERO);             // advertising

        assertEquals(0, new BigDecimal("5000.00").compareTo(result.frontGross()),
                "Front gross should be $5,000");
        assertEquals(0, new BigDecimal("900.00").compareTo(result.backGross()),
                "Back gross (holdback) should be $900");
        assertEquals(0, new BigDecimal("5900.00").compareTo(result.totalGross()),
                "Total gross should be $5,900");
    }

    @Test
    void testHoldbackByPercentage() {
        // holdbackAmt is 0, so use holdbackPct * invoice / 100
        // holdbackPct = 3%, invoice = $30,000 -> holdback = $900
        PricingResult result = engine.calculateDealPricing(
                new BigDecimal("37000.00"),
                new BigDecimal("30000.00"),
                new BigDecimal("35000.00"),
                BigDecimal.ZERO,              // holdback amount = 0 -> use pct
                new BigDecimal("3.00"),       // 3% holdback
                BigDecimal.ZERO,
                BigDecimal.ZERO);

        assertEquals(0, new BigDecimal("900.00").compareTo(result.holdback()),
                "Holdback should be 3% of $30,000 = $900");
    }

    @Test
    void testMarginPercentage() {
        // totalGross / sellingPrice * 100
        // Using values from testGrossCalculation: totalGross = $5900, sellingPrice = $35000
        // margin = 5900 / 35000 * 100 = 16.8571%
        PricingResult result = engine.calculateDealPricing(
                new BigDecimal("37000.00"),
                new BigDecimal("30000.00"),
                new BigDecimal("35000.00"),
                new BigDecimal("900.00"),
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO);

        BigDecimal expectedMargin = new BigDecimal("16.8571");
        assertEquals(0, expectedMargin.compareTo(result.marginPct()),
                "Margin should be 16.8571%, got " + result.marginPct());
    }

    @Test
    void testDealerCost() {
        // dealerCost = invoice - holdback
        // invoice = $30,000, holdback = $900 -> dealerCost = $29,100
        PricingResult result = engine.calculateDealPricing(
                new BigDecimal("37000.00"),
                new BigDecimal("30000.00"),
                new BigDecimal("35000.00"),
                new BigDecimal("900.00"),
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO);

        assertEquals(0, new BigDecimal("29100.00").compareTo(result.dealerCost()),
                "Dealer cost should be invoice - holdback = $29,100");
    }
}
