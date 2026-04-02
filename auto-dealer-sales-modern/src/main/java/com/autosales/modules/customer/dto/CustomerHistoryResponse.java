package com.autosales.modules.customer.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerHistoryResponse {

    private Integer customerId;
    private String customerName;
    private String repeatStatus;
    private Integer totalPurchases;
    private BigDecimal totalSpent;
    private BigDecimal averageDeal;
    private List<DealSummary> deals;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DealSummary {
        private String dealNumber;
        private LocalDate dealDate;
        private String vin;
        private String yearMakeModel;
        private String dealType;
        private BigDecimal salePrice;
        private BigDecimal tradeAllow;
    }
}
