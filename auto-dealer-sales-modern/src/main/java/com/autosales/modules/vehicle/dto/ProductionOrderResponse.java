package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductionOrderResponse {

    private String productionId;
    private String vin;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String vehicleDesc;
    private String plantCode;
    private LocalDate buildDate;
    private String buildStatus;
    private String buildStatusName;
    private String allocatedDealer;
    private LocalDate allocationDate;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;
}
