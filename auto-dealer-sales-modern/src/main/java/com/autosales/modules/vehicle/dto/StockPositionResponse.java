package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockPositionResponse {

    private String dealerCode;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String modelDesc;
    private Short onHandCount;
    private Short inTransitCount;
    private Short allocatedCount;
    private Short onHoldCount;
    private Short soldMtd;
    private Short soldYtd;
    private Short reorderPoint;
    private boolean lowStockAlert;
}
