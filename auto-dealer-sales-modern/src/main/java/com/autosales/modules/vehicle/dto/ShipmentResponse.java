package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShipmentResponse {

    private String shipmentId;
    private String carrierCode;
    private String carrierName;
    private String originPlant;
    private String destDealer;
    private String transportMode;
    private Short vehicleCount;
    private LocalDate shipDate;
    private LocalDate estArrivalDate;
    private LocalDate actArrivalDate;
    private String shipmentStatus;
    private String statusName;
    private List<ShipmentVehicleResponse> vehicles;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;
}
