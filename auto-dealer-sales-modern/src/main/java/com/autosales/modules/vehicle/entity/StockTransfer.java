package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "stock_transfer")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockTransfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transfer_id")
    private Integer transferId;

    @Column(name = "from_dealer", nullable = false)
    private String fromDealer;

    @Column(name = "to_dealer", nullable = false)
    private String toDealer;

    @Column(name = "vin", nullable = false)
    private String vin;

    @Column(name = "transfer_status", nullable = false)
    private String transferStatus;

    @Column(name = "requested_by", nullable = false)
    private String requestedBy;

    @Column(name = "approved_by")
    private String approvedBy;

    @Column(name = "requested_ts", nullable = false)
    private LocalDateTime requestedTs;

    @Column(name = "approved_ts")
    private LocalDateTime approvedTs;

    @Column(name = "completed_ts")
    private LocalDateTime completedTs;
}
