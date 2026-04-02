package com.autosales.modules.sales.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "trade_in")
public class TradeIn {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "trade_id")
    private Integer tradeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "deal_number", nullable = false)
    private SalesDeal salesDeal;

    @Column(name = "vin", length = 17)
    private String vin;

    @Column(name = "trade_year", nullable = false)
    private Short tradeYear;

    @Column(name = "trade_make", nullable = false, length = 20)
    private String tradeMake;

    @Column(name = "trade_model", nullable = false, length = 30)
    private String tradeModel;

    @Column(name = "trade_color", length = 15)
    private String tradeColor;

    @Column(name = "odometer", nullable = false)
    private Integer odometer;

    @Column(name = "condition_code", nullable = false, length = 1)
    private String conditionCode;

    @Column(name = "acv_amount", nullable = false, precision = 11, scale = 2)
    private BigDecimal acvAmount;

    @Column(name = "allowance_amt", nullable = false, precision = 11, scale = 2)
    private BigDecimal allowanceAmt;

    @Column(name = "over_allow", nullable = false, precision = 9, scale = 2)
    private BigDecimal overAllow;

    @Column(name = "payoff_amt", nullable = false, precision = 11, scale = 2)
    private BigDecimal payoffAmt;

    @Column(name = "payoff_bank", length = 40)
    private String payoffBank;

    @Column(name = "payoff_acct", length = 20)
    private String payoffAcct;

    @Column(name = "appraised_by", nullable = false, length = 8)
    private String appraisedBy;

    @Column(name = "appraised_ts", nullable = false)
    private LocalDateTime appraisedTs;
}
