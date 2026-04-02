package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockAlertResponse {

    private String alertType;
    private String dealerCode;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String modelDesc;
    private int currentCount;
    private int reorderPoint;
    private int deficit;
    private int suggestedOrder;
}
