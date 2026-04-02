package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "stock_snapshot")
@IdClass(StockSnapshotId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockSnapshot {

    @Id
    @Column(name = "snapshot_date")
    private LocalDate snapshotDate;

    @Id
    @Column(name = "dealer_code")
    private String dealerCode;

    @Id
    @Column(name = "model_year")
    private Short modelYear;

    @Id
    @Column(name = "make_code")
    private String makeCode;

    @Id
    @Column(name = "model_code")
    private String modelCode;

    @Column(name = "on_hand_count", nullable = false)
    private Short onHandCount;

    @Column(name = "in_transit_count", nullable = false)
    private Short inTransitCount;

    @Column(name = "on_hold_count", nullable = false)
    private Short onHoldCount;

    @Column(name = "total_value", nullable = false)
    private BigDecimal totalValue;

    @Column(name = "avg_days_in_stock", nullable = false)
    private Short avgDaysInStock;
}
