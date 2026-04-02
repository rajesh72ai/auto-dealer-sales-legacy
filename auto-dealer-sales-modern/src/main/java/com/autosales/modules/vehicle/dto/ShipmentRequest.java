package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShipmentRequest {

    private String carrierCode;
    private String carrierName;
    private String originPlant;
    private String destDealer;
    private String transportMode;
    private LocalDate shipDate;
    private LocalDate estArrivalDate;
}
