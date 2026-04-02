package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Vehicle lease payment calculator.
 * Port of COMLESL0.cbl — computes monthly depreciation, finance charge,
 * tax, drive-off amount, total cost, and equivalent APR from money factor.
 *
 * <p>All monetary amounts use BigDecimal with scale 2 and RoundingMode.HALF_UP.</p>
 */
@Component
public class LeaseCalculator {

    private static final int MONEY_SCALE = 2;
    private static final int RATE_SCALE = 6;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;
    private static final BigDecimal HUNDRED = new BigDecimal("100");
    private static final BigDecimal APR_FACTOR = new BigDecimal("2400");

    /**
     * Calculate a vehicle lease.
     *
     * @param capitalizedCost  gross capitalized cost (vehicle price + extras)
     * @param capCostReduction cap cost reduction (down payment + trade equity + rebates)
     * @param residualPct      residual value as a percentage of capitalized cost
     * @param moneyFactor      money factor (e.g., 0.00125 ~ 3.0% APR)
     * @param termMonths       lease term in months
     * @param taxRate          sales tax rate as a percentage (e.g., 7.50 = 7.50%)
     * @param acqFee           acquisition fee
     * @param securityDeposit  refundable security deposit
     * @return complete lease calculation breakdown
     * @throws IllegalArgumentException if required parameters are null or invalid
     */
    public LeaseCalculationResult calculate(
            BigDecimal capitalizedCost,
            BigDecimal capCostReduction,
            BigDecimal residualPct,
            BigDecimal moneyFactor,
            int termMonths,
            BigDecimal taxRate,
            BigDecimal acqFee,
            BigDecimal securityDeposit) {

        validateInputs(capitalizedCost, capCostReduction, residualPct, moneyFactor, termMonths);

        capitalizedCost = defaultZero(capitalizedCost);
        capCostReduction = defaultZero(capCostReduction);
        residualPct = defaultZero(residualPct);
        moneyFactor = defaultZero(moneyFactor);
        taxRate = defaultZero(taxRate);
        acqFee = defaultZero(acqFee);
        securityDeposit = defaultZero(securityDeposit);

        BigDecimal termBD = new BigDecimal(termMonths);

        // Residual amount = capitalizedCost * residualPct / 100
        BigDecimal residualAmount = capitalizedCost.multiply(residualPct)
                .divide(HUNDRED, MONEY_SCALE, ROUNDING);

        // Adjusted capitalized cost = capitalizedCost + acqFee - capCostReduction
        BigDecimal adjCapCost = capitalizedCost.add(acqFee).subtract(capCostReduction)
                .setScale(MONEY_SCALE, ROUNDING);

        // Monthly depreciation = (adjCapCost - residualAmount) / termMonths
        BigDecimal monthlyDepreciation = adjCapCost.subtract(residualAmount)
                .divide(termBD, MONEY_SCALE, ROUNDING);

        // Monthly finance charge = (adjCapCost + residualAmount) * moneyFactor
        BigDecimal monthlyFinanceCharge = adjCapCost.add(residualAmount)
                .multiply(moneyFactor)
                .setScale(MONEY_SCALE, ROUNDING);

        // Monthly tax = (monthlyDepreciation + monthlyFinanceCharge) * taxRate / 100
        BigDecimal monthlyTax = monthlyDepreciation.add(monthlyFinanceCharge)
                .multiply(taxRate)
                .divide(HUNDRED, MONEY_SCALE, ROUNDING);

        // Total monthly payment
        BigDecimal totalMonthly = monthlyDepreciation.add(monthlyFinanceCharge).add(monthlyTax)
                .setScale(MONEY_SCALE, ROUNDING);

        // Drive-off = first month + security deposit + acquisition fee + cap cost reduction
        BigDecimal driveOff = totalMonthly.add(securityDeposit).add(acqFee).add(capCostReduction)
                .setScale(MONEY_SCALE, ROUNDING);

        // Total cost = totalMonthly * term + capCostReduction + acqFee
        BigDecimal totalCost = totalMonthly.multiply(termBD)
                .add(capCostReduction).add(acqFee)
                .setScale(MONEY_SCALE, ROUNDING);

        // Equivalent APR (approximate) = moneyFactor * 2400
        BigDecimal equivalentApr = moneyFactor.multiply(APR_FACTOR)
                .setScale(MONEY_SCALE, ROUNDING);

        return new LeaseCalculationResult(
                residualAmount,
                adjCapCost,
                monthlyDepreciation,
                monthlyFinanceCharge,
                monthlyTax,
                totalMonthly,
                driveOff,
                totalCost,
                equivalentApr
        );
    }

    private void validateInputs(BigDecimal capitalizedCost, BigDecimal capCostReduction,
                                BigDecimal residualPct, BigDecimal moneyFactor, int termMonths) {
        if (capitalizedCost == null || capitalizedCost.signum() <= 0) {
            throw new IllegalArgumentException("Capitalized cost must be a positive amount");
        }
        if (termMonths <= 0) {
            throw new IllegalArgumentException("Term must be a positive number of months");
        }
        if (residualPct != null && (residualPct.signum() < 0 || residualPct.compareTo(HUNDRED) > 0)) {
            throw new IllegalArgumentException("Residual percentage must be between 0 and 100");
        }
        if (moneyFactor != null && moneyFactor.signum() < 0) {
            throw new IllegalArgumentException("Money factor must not be negative");
        }
    }

    private BigDecimal defaultZero(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }
}
