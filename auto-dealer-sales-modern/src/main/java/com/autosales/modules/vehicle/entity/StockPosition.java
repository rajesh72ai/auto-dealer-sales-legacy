package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "stock_position")
@IdClass(StockPositionId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockPosition {

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

    @Column(name = "allocated_count", nullable = false)
    private Short allocatedCount;

    @Column(name = "on_hold_count", nullable = false)
    private Short onHoldCount;

    @Column(name = "sold_mtd", nullable = false)
    private Short soldMtd;

    @Column(name = "sold_ytd", nullable = false)
    private Short soldYtd;

    @Column(name = "reorder_point", nullable = false)
    private Short reorderPoint;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
