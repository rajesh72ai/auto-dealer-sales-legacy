package com.autosales.modules.sales.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sales_deal")
public class SalesDeal {

    @Id
    @Column(name = "deal_number", length = 10)
    private String dealNumber;

    @Column(name = "dealer_code", nullable = false, length = 5)
    private String dealerCode;

    @Column(name = "customer_id", nullable = false)
    private Integer customerId;

    @Column(name = "vin", nullable = false, length = 17)
    private String vin;

    @Column(name = "salesperson_id", nullable = false, length = 8)
    private String salespersonId;

    @Column(name = "sales_manager_id", length = 8)
    private String salesManagerId;

    @Column(name = "deal_type", nullable = false, length = 1)
    private String dealType;

    @Column(name = "deal_status", nullable = false, length = 2)
    private String dealStatus;

    @Column(name = "vehicle_price", nullable = false, precision = 11, scale = 2)
    private BigDecimal vehiclePrice;

    @Column(name = "total_options", nullable = false, precision = 9, scale = 2)
    private BigDecimal totalOptions;

    @Column(name = "destination_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal destinationFee;

    @Column(name = "subtotal", nullable = false, precision = 11, scale = 2)
    private BigDecimal subtotal;

    @Column(name = "trade_allow", nullable = false, precision = 11, scale = 2)
    private BigDecimal tradeAllow;

    @Column(name = "trade_payoff", nullable = false, precision = 11, scale = 2)
    private BigDecimal tradePayoff;

    @Column(name = "net_trade", nullable = false, precision = 11, scale = 2)
    private BigDecimal netTrade;

    @Column(name = "rebates_applied", nullable = false, precision = 9, scale = 2)
    private BigDecimal rebatesApplied;

    @Column(name = "discount_amt", nullable = false, precision = 9, scale = 2)
    private BigDecimal discountAmt;

    @Column(name = "doc_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal docFee;

    @Column(name = "state_tax", nullable = false, precision = 9, scale = 2)
    private BigDecimal stateTax;

    @Column(name = "county_tax", nullable = false, precision = 9, scale = 2)
    private BigDecimal countyTax;

    @Column(name = "city_tax", nullable = false, precision = 9, scale = 2)
    private BigDecimal cityTax;

    @Column(name = "title_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal titleFee;

    @Column(name = "reg_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal regFee;

    @Column(name = "total_price", nullable = false, precision = 11, scale = 2)
    private BigDecimal totalPrice;

    @Column(name = "down_payment", nullable = false, precision = 11, scale = 2)
    private BigDecimal downPayment;

    @Column(name = "amount_financed", nullable = false, precision = 11, scale = 2)
    private BigDecimal amountFinanced;

    @Column(name = "front_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal frontGross;

    @Column(name = "back_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal backGross;

    @Column(name = "total_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal totalGross;

    @Column(name = "deal_date")
    private LocalDate dealDate;

    @Column(name = "delivery_date")
    private LocalDate deliveryDate;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
