package com.autosales.modules.sales.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "deal_line_item")
@IdClass(DealLineItemId.class)
public class DealLineItem {

    @Id
    @Column(name = "deal_number", length = 10)
    private String dealNumber;

    @Id
    @Column(name = "line_seq")
    private Short lineSeq;

    @Column(name = "line_type", nullable = false, length = 2)
    private String lineType;

    @Column(name = "description", nullable = false, length = 40)
    private String description;

    @Column(name = "amount", nullable = false, precision = 11, scale = 2)
    private BigDecimal amount;

    @Column(name = "cost", nullable = false, precision = 11, scale = 2)
    private BigDecimal cost;

    @Column(name = "taxable_flag", nullable = false, length = 1)
    private String taxableFlag;
}
