package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "vehicle")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Vehicle {

    @Id
    @Column(name = "vin")
    private String vin;

    @Column(name = "model_year", nullable = false)
    private Short modelYear;

    @Column(name = "make_code", nullable = false)
    private String makeCode;

    @Column(name = "model_code", nullable = false)
    private String modelCode;

    @Column(name = "exterior_color", nullable = false)
    private String exteriorColor;

    @Column(name = "interior_color", nullable = false)
    private String interiorColor;

    @Column(name = "engine_num")
    private String engineNum;

    @Column(name = "production_date")
    private LocalDate productionDate;

    @Column(name = "ship_date")
    private LocalDate shipDate;

    @Column(name = "receive_date")
    private LocalDate receiveDate;

    @Column(name = "vehicle_status", nullable = false)
    private String vehicleStatus;

    @Column(name = "dealer_code")
    private String dealerCode;

    @Column(name = "lot_location")
    private String lotLocation;

    @Column(name = "stock_number")
    private String stockNumber;

    @Column(name = "days_in_stock", nullable = false)
    private Short daysInStock;

    @Column(name = "pdi_complete", nullable = false)
    private String pdiComplete;

    @Column(name = "pdi_date")
    private LocalDate pdiDate;

    @Column(name = "damage_flag", nullable = false)
    private String damageFlag;

    @Column(name = "damage_desc")
    private String damageDesc;

    @Column(name = "odometer", nullable = false)
    private Integer odometer;

    @Column(name = "key_number")
    private String keyNumber;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
