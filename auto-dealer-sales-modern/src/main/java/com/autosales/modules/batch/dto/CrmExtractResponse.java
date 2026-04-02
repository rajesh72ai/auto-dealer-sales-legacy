package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CrmExtractResponse {

    private LocalDateTime extractedAt;
    private Integer customersExtracted;
    private List<CrmCustomerRecord> records;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CrmCustomerRecord {
        private Integer customerId;
        private String firstName;
        private String lastName;
        private String email;
        private String cellPhone;
        private String dealerCode;
        private Integer totalDeals;
        private BigDecimal totalSpent;
        private LocalDate lastDealDate;
        private LocalDate extractDate;
    }
}
