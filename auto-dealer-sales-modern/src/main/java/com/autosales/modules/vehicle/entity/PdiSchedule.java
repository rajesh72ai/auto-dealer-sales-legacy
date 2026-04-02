package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "pdi_schedule")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PdiSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pdi_id")
    private Integer pdiId;

    @Column(name = "vin", nullable = false)
    private String vin;

    @Column(name = "dealer_code", nullable = false)
    private String dealerCode;

    @Column(name = "scheduled_date", nullable = false)
    private LocalDate scheduledDate;

    @Column(name = "technician_id")
    private String technicianId;

    @Column(name = "pdi_status", nullable = false)
    private String pdiStatus;

    @Column(name = "checklist_items", nullable = false)
    private Short checklistItems;

    @Column(name = "items_passed", nullable = false)
    private Short itemsPassed;

    @Column(name = "items_failed", nullable = false)
    private Short itemsFailed;

    @Column(name = "notes")
    private String notes;

    @Column(name = "completed_ts")
    private LocalDateTime completedTs;
}
