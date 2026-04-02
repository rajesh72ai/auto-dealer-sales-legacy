package com.autosales.modules.batch.entity;

import jakarta.persistence.*;
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
@Entity
@Table(name = "daily_sales_summary")
@IdClass(DailySalesSummaryId.class)
public class DailySalesSummary {

    @Id
    @Column(name = "summary_date")
    private LocalDate summaryDate;

    @Id
    @Column(name = "dealer_code", length = 5)
    private String dealerCode;

    @Id
    @Column(name = "model_year")
    private Short modelYear;

    @Id
    @Column(name = "make_code", length = 3)
    private String makeCode;

    @Id
    @Column(name = "model_code", length = 6)
    private String modelCode;

    @Column(name = "units_sold", nullable = false)
    private Short unitsSold;

    @Column(name = "total_revenue", nullable = false, precision = 13, scale = 2)
    private BigDecimal totalRevenue;

    @Column(name = "total_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal totalGross;

    @Column(name = "front_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal frontGross;

    @Column(name = "back_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal backGross;

    @Column(name = "avg_selling_price", nullable = false, precision = 11, scale = 2)
    private BigDecimal avgSellingPrice;

    @Column(name = "avg_gross_per_unit", nullable = false, precision = 9, scale = 2)
    private BigDecimal avgGrossPerUnit;
}
