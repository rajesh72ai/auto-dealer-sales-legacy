package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "stock_adjustment")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockAdjustment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "adjust_id")
    private Integer adjustId;

    @Column(name = "dealer_code", nullable = false)
    private String dealerCode;

    @Column(name = "vin", nullable = false)
    private String vin;

    @Column(name = "adjust_type", nullable = false)
    private String adjustType;

    @Column(name = "adjust_reason", nullable = false)
    private String adjustReason;

    @Column(name = "old_status", nullable = false)
    private String oldStatus;

    @Column(name = "new_status", nullable = false)
    private String newStatus;

    @Column(name = "adjusted_by", nullable = false)
    private String adjustedBy;

    @Column(name = "adjusted_ts", nullable = false)
    private LocalDateTime adjustedTs;
}
