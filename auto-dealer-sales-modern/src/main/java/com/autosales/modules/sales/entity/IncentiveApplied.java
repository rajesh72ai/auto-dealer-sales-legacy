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
@Table(name = "incentive_applied")
@IdClass(IncentiveAppliedId.class)
public class IncentiveApplied {

    @Id
    @Column(name = "deal_number", length = 10)
    private String dealNumber;

    @Id
    @Column(name = "incentive_id", length = 10)
    private String incentiveId;

    @Column(name = "amount_applied", nullable = false, precision = 9, scale = 2)
    private BigDecimal amountApplied;

    @Column(name = "applied_ts", nullable = false)
    private LocalDateTime appliedTs;
}
