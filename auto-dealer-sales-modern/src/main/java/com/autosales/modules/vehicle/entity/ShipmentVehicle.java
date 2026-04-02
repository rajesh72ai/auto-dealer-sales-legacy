package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "shipment_vehicle")
@IdClass(ShipmentVehicleId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentVehicle {

    @Id
    @Column(name = "shipment_id")
    private String shipmentId;

    @Id
    @Column(name = "vin")
    private String vin;

    @Column(name = "load_sequence", nullable = false)
    private Short loadSequence;
}
