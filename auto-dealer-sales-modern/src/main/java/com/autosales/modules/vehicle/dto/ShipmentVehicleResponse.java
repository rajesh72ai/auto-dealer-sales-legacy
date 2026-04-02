package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShipmentVehicleResponse {

    private String shipmentId;
    private String vin;
    private String vehicleDesc;
    private Short loadSequence;
}
