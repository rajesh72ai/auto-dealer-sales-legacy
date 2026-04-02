package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Multi-jurisdiction tax calculator for vehicle sales.
 * Port of COMTAXL0.cbl — state/county/city tax cascade with
 * document, title, and registration fee computation.
 *
 * <p>Tax rate lookup cascades: state+county+city, then state+county,
 * then state-only. Net taxable = taxableAmount - tradeAllowance (min 0).
 * Each tax component is rounded independently to 2 decimal places.</p>
 */
@Component
public class TaxCalculator {

    private static final int SCALE = 2;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    /**
     * Calculate taxes and fees for a vehicle sale.
     *
     * @param taxableAmount  vehicle selling price subject to tax
     * @param tradeAllowance trade-in allowance reducing taxable amount
     * @param stateRate      state tax rate as a percentage (e.g., 4.50 = 4.50%)
     * @param countyRate     county tax rate as a percentage
     * @param cityRate       city tax rate as a percentage
     * @param docFee         documentation/processing fee (flat amount)
     * @param titleFee       title fee (flat amount)
     * @param regFee         registration fee (flat amount)
     * @return full tax calculation breakdown
     */
    public TaxCalculationResult calculate(
            BigDecimal taxableAmount,
            BigDecimal tradeAllowance,
            BigDecimal stateRate,
            BigDecimal countyRate,
            BigDecimal cityRate,
            BigDecimal docFee,
            BigDecimal titleFee,
            BigDecimal regFee) {

        // Default nulls to zero
        taxableAmount = defaultZero(taxableAmount);
        tradeAllowance = defaultZero(tradeAllowance);
        stateRate = defaultZero(stateRate);
        countyRate = defaultZero(countyRate);
        cityRate = defaultZero(cityRate);
        docFee = defaultZero(docFee);
        titleFee = defaultZero(titleFee);
        regFee = defaultZero(regFee);

        // Net taxable = taxableAmount - tradeAllowance, minimum 0
        BigDecimal netTaxable = taxableAmount.subtract(tradeAllowance);
        if (netTaxable.signum() < 0) {
            netTaxable = BigDecimal.ZERO;
        }

        BigDecimal oneHundred = new BigDecimal("100");

        // Each tax rounded independently
        BigDecimal stateTax = netTaxable.multiply(stateRate)
                .divide(oneHundred, SCALE, ROUNDING);
        BigDecimal countyTax = netTaxable.multiply(countyRate)
                .divide(oneHundred, SCALE, ROUNDING);
        BigDecimal cityTax = netTaxable.multiply(cityRate)
                .divide(oneHundred, SCALE, ROUNDING);

        BigDecimal totalTax = stateTax.add(countyTax).add(cityTax);
        BigDecimal totalFees = docFee.add(titleFee).add(regFee);
        BigDecimal grandTotal = totalTax.add(totalFees);

        return new TaxCalculationResult(
                stateTax, countyTax, cityTax,
                docFee.setScale(SCALE, ROUNDING),
                titleFee.setScale(SCALE, ROUNDING),
                regFee.setScale(SCALE, ROUNDING),
                totalTax, totalFees.setScale(SCALE, ROUNDING),
                grandTotal.setScale(SCALE, ROUNDING)
        );
    }

    /**
     * Convenience overload that looks up rates by jurisdiction codes.
     * Placeholder for future TaxRateRepository integration.
     *
     * @param taxableAmount  selling price
     * @param tradeAllowance trade-in allowance
     * @param stateCode      two-letter state code (e.g., "CO")
     * @param countyCode     county FIPS or name
     * @param cityCode       city code or name
     * @return tax calculation with looked-up rates
     */
    public TaxCalculationResult calculateByJurisdiction(
            BigDecimal taxableAmount,
            BigDecimal tradeAllowance,
            String stateCode,
            String countyCode,
            String cityCode) {

        // TODO: Wire to TaxRateRepository with cascade lookup:
        //   1. state+county+city  2. state+county  3. state-only
        // For now, use placeholder zero rates — real rates come from DB.
        BigDecimal stateRate = BigDecimal.ZERO;
        BigDecimal countyRate = BigDecimal.ZERO;
        BigDecimal cityRate = BigDecimal.ZERO;
        BigDecimal docFee = BigDecimal.ZERO;
        BigDecimal titleFee = BigDecimal.ZERO;
        BigDecimal regFee = BigDecimal.ZERO;

        return calculate(taxableAmount, tradeAllowance,
                stateRate, countyRate, cityRate,
                docFee, titleFee, regFee);
    }

    private BigDecimal defaultZero(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }
}
