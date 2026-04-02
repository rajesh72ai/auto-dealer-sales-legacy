package com.autosales.modules.registration.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "recall_vehicle")
@IdClass(RecallVehicleId.class)
public class RecallVehicle {

    @Id
    @Column(name = "recall_id", length = 10)
    private String recallId;

    @Id
    @Column(name = "vin", length = 17)
    private String vin;

    @Column(name = "dealer_code", length = 5)
    private String dealerCode;

    @Column(name = "recall_status", nullable = false, length = 2)
    private String recallStatus;

    @Column(name = "notified_date")
    private LocalDate notifiedDate;

    @Column(name = "scheduled_date")
    private LocalDate scheduledDate;

    @Column(name = "completed_date")
    private LocalDate completedDate;

    @Column(name = "technician_id", length = 8)
    private String technicianId;

    @Column(name = "parts_ordered", nullable = false, length = 1)
    private String partsOrdered;

    @Column(name = "parts_avail", nullable = false, length = 1)
    private String partsAvail;
}
