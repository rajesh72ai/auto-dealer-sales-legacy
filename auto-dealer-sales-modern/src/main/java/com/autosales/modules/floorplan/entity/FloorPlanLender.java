package com.autosales.modules.floorplan.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "floor_plan_lender")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FloorPlanLender {

    @Id
    @Column(name = "lender_id")
    private String lenderId;

    @Column(name = "lender_name", nullable = false)
    private String lenderName;

    @Column(name = "contact_name")
    private String contactName;

    @Column(name = "phone")
    private String phone;

    @Column(name = "base_rate", nullable = false)
    private BigDecimal baseRate;

    @Column(name = "spread", nullable = false)
    private BigDecimal spread;

    @Column(name = "curtailment_days", nullable = false)
    private Integer curtailmentDays;

    @Column(name = "free_floor_days", nullable = false)
    private Integer freeFloorDays;
}
