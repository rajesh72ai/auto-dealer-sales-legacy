package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleListResponse {

    private String vin;
    private String stockNumber;
    private String vehicleDesc;
    private String vehicleStatus;
    private String statusName;
    private String exteriorColor;
    private Short daysInStock;
    private String dealerCode;
    private String lotLocation;
    private String pdiComplete;
    private String damageFlag;
}
