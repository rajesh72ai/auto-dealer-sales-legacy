package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleReceiveRequest {

    private String lotLocation;
    private String stockNumber;
    private Integer odometer;
    private String damageFlag;
    private String damageDesc;
    private String keyNumber;
    private String inspectionNotes;
}
