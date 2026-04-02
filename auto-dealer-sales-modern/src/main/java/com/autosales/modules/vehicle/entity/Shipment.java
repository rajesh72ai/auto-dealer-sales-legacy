package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "shipment")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Shipment {

    @Id
    @Column(name = "shipment_id")
    private String shipmentId;

    @Column(name = "carrier_code", nullable = false)
    private String carrierCode;

    @Column(name = "carrier_name")
    private String carrierName;

    @Column(name = "origin_plant", nullable = false)
    private String originPlant;

    @Column(name = "dest_dealer", nullable = false)
    private String destDealer;

    @Column(name = "transport_mode", nullable = false)
    private String transportMode;

    @Column(name = "vehicle_count", nullable = false)
    private Short vehicleCount;

    @Column(name = "ship_date")
    private LocalDate shipDate;

    @Column(name = "est_arrival_date")
    private LocalDate estArrivalDate;

    @Column(name = "act_arrival_date")
    private LocalDate actArrivalDate;

    @Column(name = "shipment_status", nullable = false)
    private String shipmentStatus;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
