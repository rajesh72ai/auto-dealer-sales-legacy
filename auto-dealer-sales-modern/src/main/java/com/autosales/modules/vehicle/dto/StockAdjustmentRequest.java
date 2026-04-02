package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockAdjustmentRequest {

    private String dealerCode;
    private String vin;
    private String adjustType;
    private String adjustReason;
    private String adjustedBy;
}
