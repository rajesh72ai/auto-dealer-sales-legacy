package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailySalesSummaryResponse {

    private LocalDate summaryDate;
    private String dealerCode;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private Short unitsSold;
    private BigDecimal totalRevenue;
    private BigDecimal totalGross;
    private BigDecimal frontGross;
    private BigDecimal backGross;
    private BigDecimal avgSellingPrice;
    private BigDecimal avgGrossPerUnit;
}
