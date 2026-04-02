package com.autosales.modules.sales.dto;

import lombok.*;

import java.math.BigDecimal;

/**
 * Negotiation pricing breakdown response.
 * Port of SLSDESK0.cbl — desking screen pricing display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NegotiationResponse {

    private String dealNumber;

    // --- Pricing breakdown ---
    private BigDecimal msrp;
    private BigDecimal invoicePrice;    // manager-only visibility
    private BigDecimal holdback;        // hidden from customer view
    private BigDecimal currentOffer;
    private BigDecimal counterOffer;
    private BigDecimal discount;
    private BigDecimal rebates;
    private BigDecimal netTrade;

    // --- Taxes ---
    private BigDecimal stateTax;
    private BigDecimal countyTax;
    private BigDecimal cityTax;

    // --- Fees ---
    private BigDecimal docFee;
    private BigDecimal titleFee;
    private BigDecimal regFee;

    // --- Totals ---
    private BigDecimal totalPrice;
    private BigDecimal downPayment;
    private BigDecimal amountFinanced;

    // --- Gross analysis (manager-only) ---
    private BigDecimal frontGross;
    private BigDecimal backGross;
    private BigDecimal totalGross;
    private BigDecimal marginPct;       // manager-only

    // --- Notes ---
    private String deskNotes;
}
