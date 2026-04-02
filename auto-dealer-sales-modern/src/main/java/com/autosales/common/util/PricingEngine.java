package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Vehicle deal pricing and gross profit analysis.
 * Port of COMPRCL0.cbl — dealer cost, front/back gross, and margin calculation.
 *
 * <p>All monetary amounts use BigDecimal with scale 2 and RoundingMode.HALF_UP.
 * Percentages use scale 4 for precision.</p>
 */
@Component
public class PricingEngine {

    private static final int MONEY_SCALE = 2;
    private static final int PCT_SCALE = 4;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    /**
     * Calculate deal pricing gross analysis.
     *
     * @param msrp            manufacturer's suggested retail price
     * @param invoice          dealer invoice price
     * @param sellingPrice     actual selling price to customer
     * @param holdbackAmt      holdback as a fixed dollar amount (takes precedence if > 0)
     * @param holdbackPct      holdback as a percentage of invoice (used when holdbackAmt <= 0)
     * @param destinationFee   destination/freight charge
     * @param advertisingFee   regional advertising assessment
     * @return complete pricing breakdown
     */
    public PricingResult calculateDealPricing(
            BigDecimal msrp,
            BigDecimal invoice,
            BigDecimal sellingPrice,
            BigDecimal holdbackAmt,
            BigDecimal holdbackPct,
            BigDecimal destinationFee,
            BigDecimal advertisingFee) {

        msrp = defaultZero(msrp);
        invoice = defaultZero(invoice);
        sellingPrice = defaultZero(sellingPrice);
        holdbackAmt = defaultZero(holdbackAmt);
        holdbackPct = defaultZero(holdbackPct);
        destinationFee = defaultZero(destinationFee);
        advertisingFee = defaultZero(advertisingFee);

        // Total MSRP includes destination
        BigDecimal totalMsrp = msrp.add(destinationFee)
                .setScale(MONEY_SCALE, ROUNDING);

        // Total invoice includes destination + advertising
        BigDecimal totalInvoice = invoice.add(destinationFee).add(advertisingFee)
                .setScale(MONEY_SCALE, ROUNDING);

        // Holdback: use fixed amount if provided, otherwise calculate from invoice
        BigDecimal holdback;
        if (holdbackAmt.signum() > 0) {
            holdback = holdbackAmt.setScale(MONEY_SCALE, ROUNDING);
        } else {
            holdback = invoice.multiply(holdbackPct)
                    .divide(HUNDRED, MONEY_SCALE, ROUNDING);
        }

        // Dealer cost = invoice - holdback
        BigDecimal dealerCost = invoice.subtract(holdback)
                .setScale(MONEY_SCALE, ROUNDING);

        // Front gross = selling price - invoice
        BigDecimal frontGross = sellingPrice.subtract(invoice)
                .setScale(MONEY_SCALE, ROUNDING);

        // Back gross = holdback
        BigDecimal backGross = holdback;

        // Total gross = front + back
        BigDecimal totalGross = frontGross.add(backGross)
                .setScale(MONEY_SCALE, ROUNDING);

        // Margin percentage = totalGross / sellingPrice * 100
        BigDecimal marginPct;
        if (sellingPrice.signum() == 0) {
            marginPct = BigDecimal.ZERO.setScale(PCT_SCALE, ROUNDING);
        } else {
            marginPct = totalGross.multiply(HUNDRED)
                    .divide(sellingPrice, PCT_SCALE, ROUNDING);
        }

        return new PricingResult(
                msrp.setScale(MONEY_SCALE, ROUNDING),
                invoice.setScale(MONEY_SCALE, ROUNDING),
                totalMsrp,
                totalInvoice,
                holdback,
                dealerCost,
                frontGross,
                backGross,
                totalGross,
                marginPct
        );
    }

    private BigDecimal defaultZero(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }
}
