package com.autosales.modules.finance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "fi_deal_product")
@IdClass(FiDealProductId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FiDealProduct {

    @Id
    @Column(name = "deal_number")
    private String dealNumber;

    @Id
    @Column(name = "product_seq")
    private Short productSeq;

    @Column(name = "product_type", nullable = false)
    private String productType;

    @Column(name = "product_name", nullable = false)
    private String productName;

    @Column(name = "provider")
    private String provider;

    @Column(name = "term_months")
    private Short termMonths;

    @Column(name = "mileage_limit")
    private Integer mileageLimit;

    @Column(name = "selling_price", nullable = false)
    private BigDecimal sellingPrice;

    @Column(name = "dealer_cost", nullable = false)
    private BigDecimal dealerCost;

    @Column(name = "gross_profit", nullable = false)
    private BigDecimal grossProfit;
}
