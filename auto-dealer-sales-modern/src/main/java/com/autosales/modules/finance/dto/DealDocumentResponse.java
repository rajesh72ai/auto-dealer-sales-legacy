package com.autosales.modules.finance.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Deal document generation response with seller, buyer, vehicle, pricing, and F&I details.
 * Port of FINDOC00.cbl — finance document assembly transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealDocumentResponse {

    private String dealNumber;
    private String documentType;    // RIC, Lease Agreement, Cash Receipt

    private Seller seller;
    private Buyer buyer;
    private Vehicle vehicle;
    private Pricing pricing;
    private FinanceTerms financeTerms;
    private List<FiProduct> fiProducts;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Seller {
        private String dealerName;
        private String address;
        private String city;
        private String state;
        private String zip;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Buyer {
        private String customerName;
        private String address;
        private String city;
        private String state;
        private String zip;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Vehicle {
        private Short year;
        private String make;
        private String modelName;
        private String vin;
        private String stockNumber;
        private Integer odometer;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Pricing {
        private BigDecimal vehiclePrice;
        private BigDecimal options;
        private BigDecimal destination;
        private BigDecimal rebates;
        private BigDecimal tradeAllowance;
        private BigDecimal taxes;
        private BigDecimal fees;
        private BigDecimal totalPrice;
        private BigDecimal downPayment;
        private BigDecimal amountFinanced;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FinanceTerms {
        private BigDecimal apr;
        private Short termMonths;
        private BigDecimal monthlyPayment;
        private BigDecimal totalOfPayments;
        private BigDecimal financeCharge;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FiProduct {
        private String productName;
        private BigDecimal retailPrice;
    }
}
