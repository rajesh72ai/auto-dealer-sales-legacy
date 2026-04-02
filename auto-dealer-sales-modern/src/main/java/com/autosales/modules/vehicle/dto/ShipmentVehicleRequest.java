package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShipmentVehicleRequest {

    private String vin;
    private Short loadSequence;
}
