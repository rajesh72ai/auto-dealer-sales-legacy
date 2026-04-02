package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockValuationResponse {

    private String dealerCode;
    private List<ValuationCategory> categories;
    private BigDecimal grandTotal;
    private BigDecimal totalAccruedInterest;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ValuationCategory {
        private String category;
        private String categoryName;
        private int count;
        private BigDecimal totalInvoice;
        private BigDecimal totalMsrp;
        private int avgDaysInStock;
        private BigDecimal holdingCost;
    }
}
