package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EtaResponse {

    private String vin;
    private String vehicleDesc;
    private String shipmentId;
    private String currentLocation;
    private int daysInTransit;
    private int estimatedDaysRemaining;
    private LocalDate estArrivalDate;
    private String transportMode;
}
