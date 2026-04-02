package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockSummaryResponse {

    private String dealerCode;
    private String dealerName;
    private int totalOnHand;
    private int totalInTransit;
    private int totalAllocated;
    private int totalOnHold;
    private int totalSoldMtd;
    private int totalSoldYtd;
    private BigDecimal totalValue;
    private int avgDaysInStock;
}
