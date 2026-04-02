package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleResponse {

    private String vin;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String exteriorColor;
    private String interiorColor;
    private String engineNum;
    private LocalDate productionDate;
    private LocalDate shipDate;
    private LocalDate receiveDate;
    private String vehicleStatus;
    private String statusName;
    private String dealerCode;
    private String lotLocation;
    private String stockNumber;
    private Short daysInStock;
    private String pdiComplete;
    private String damageFlag;
    private String damageDesc;
    private Integer odometer;
    private String keyNumber;
    private String vehicleDesc;
    private List<VehicleOptionResponse> options;
    private List<VehicleHistoryEntry> history;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;
}
