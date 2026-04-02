package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleUpdateRequest {

    private String vehicleStatus;
    private String lotLocation;
    private Integer odometer;
    private String damageFlag;
    private String damageDesc;
    private String keyNumber;
    private String reason;
}
