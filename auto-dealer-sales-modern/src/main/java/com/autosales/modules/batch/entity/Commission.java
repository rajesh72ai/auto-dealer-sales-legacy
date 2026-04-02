package com.autosales.modules.batch.entity;

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
@Table(name = "commission")
public class Commission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "commission_id")
    private Integer commissionId;

    @Column(name = "dealer_code", nullable = false, length = 5)
    private String dealerCode;

    @Column(name = "salesperson_id", nullable = false, length = 8)
    private String salespersonId;

    @Column(name = "deal_number", nullable = false, length = 10)
    private String dealNumber;

    @Column(name = "comm_type", nullable = false, length = 2)
    private String commType;

    @Column(name = "gross_amount", nullable = false, precision = 11, scale = 2)
    private BigDecimal grossAmount;

    @Column(name = "comm_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal commRate;

    @Column(name = "comm_amount", nullable = false, precision = 9, scale = 2)
    private BigDecimal commAmount;

    @Column(name = "pay_period", nullable = false, length = 6)
    private String payPeriod;

    @Column(name = "paid_flag", nullable = false, length = 1)
    private String paidFlag;

    @Column(name = "calc_ts", nullable = false)
    private LocalDateTime calcTs;
}
