package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GlPostingResponse {

    private LocalDateTime generatedAt;
    private Integer dealsProcessed;
    private BigDecimal totalRevenue;
    private BigDecimal totalCogs;
    private BigDecimal totalFiIncome;
    private BigDecimal totalTax;
    private List<GlEntry> entries;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GlEntry {
        private String dealNumber;
        private String accountCode;
        private String accountName;
        private String entryType;
        private BigDecimal amount;
    }
}
