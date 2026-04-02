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
@Table(name = "monthly_snapshot")
@IdClass(MonthlySnapshotId.class)
public class MonthlySnapshot {

    @Id
    @Column(name = "snapshot_month", length = 6)
    private String snapshotMonth;

    @Id
    @Column(name = "dealer_code", length = 5)
    private String dealerCode;

    @Column(name = "total_units_sold", nullable = false)
    private Short totalUnitsSold;

    @Column(name = "total_revenue", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalRevenue;

    @Column(name = "total_gross", nullable = false, precision = 13, scale = 2)
    private BigDecimal totalGross;

    @Column(name = "total_fi_gross", nullable = false, precision = 11, scale = 2)
    private BigDecimal totalFiGross;

    @Column(name = "avg_days_to_sell", nullable = false)
    private Short avgDaysToSell;

    @Column(name = "inventory_turn", nullable = false, precision = 5, scale = 2)
    private BigDecimal inventoryTurn;

    @Column(name = "fi_per_deal", nullable = false, precision = 9, scale = 2)
    private BigDecimal fiPerDeal;

    @Column(name = "csi_score", precision = 5, scale = 2)
    private BigDecimal csiScore;

    @Column(name = "frozen_flag", nullable = false, length = 1)
    private String frozenFlag;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;
}
