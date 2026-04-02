package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LotLocationResponse {

    private String dealerCode;
    private String locationCode;
    private String locationDesc;
    private String locationType;
    private Short maxCapacity;
    private Short currentCount;
    private String activeFlag;
    private int availableSpots;
    private BigDecimal utilizationPct;
}
