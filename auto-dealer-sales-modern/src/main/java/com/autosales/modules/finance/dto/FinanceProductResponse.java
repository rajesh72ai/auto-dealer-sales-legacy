package com.autosales.modules.finance.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * F&I product catalog response with selected products and profit summary.
 * Port of FINPRD00.cbl — F&I product menu display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FinanceProductResponse {

    private String dealNumber;
    private List<ProductItem> catalog;
    private Integer selectedCount;
    private BigDecimal totalRetail;
    private BigDecimal totalCost;
    private BigDecimal totalProfit;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProductItem {
        private String code;
        private String name;
        private Short term;
        private Integer miles;
        private BigDecimal retailPrice;
        private BigDecimal dealerCost;
        private BigDecimal profit;
        private boolean selected;
    }
}
