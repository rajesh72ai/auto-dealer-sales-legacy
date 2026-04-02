package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockAdjustmentResponse {

    private Integer adjustId;
    private String dealerCode;
    private String vin;
    private String vehicleDesc;
    private String adjustType;
    private String adjustTypeName;
    private String adjustReason;
    private String oldStatus;
    private String newStatus;
    private String adjustedBy;
    private LocalDateTime adjustedTs;
}
