package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "vehicle_status_hist")
@IdClass(VehicleStatusHistId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleStatusHist {

    @Id
    @Column(name = "vin")
    private String vin;

    @Id
    @Column(name = "status_seq")
    private Integer statusSeq;

    @Column(name = "old_status", nullable = false)
    private String oldStatus;

    @Column(name = "new_status", nullable = false)
    private String newStatus;

    @Column(name = "changed_by", nullable = false)
    private String changedBy;

    @Column(name = "change_reason")
    private String changeReason;

    @Column(name = "changed_ts", nullable = false)
    private LocalDateTime changedTs;
}
