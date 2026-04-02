package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "production_order")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductionOrder {

    @Id
    @Column(name = "production_id")
    private String productionId;

    @Column(name = "vin", nullable = false)
    private String vin;

    @Column(name = "model_year", nullable = false)
    private Short modelYear;

    @Column(name = "make_code", nullable = false)
    private String makeCode;

    @Column(name = "model_code", nullable = false)
    private String modelCode;

    @Column(name = "plant_code", nullable = false)
    private String plantCode;

    @Column(name = "build_date")
    private LocalDate buildDate;

    @Column(name = "build_status", nullable = false)
    private String buildStatus;

    @Column(name = "allocated_dealer")
    private String allocatedDealer;

    @Column(name = "allocation_date")
    private LocalDate allocationDate;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
