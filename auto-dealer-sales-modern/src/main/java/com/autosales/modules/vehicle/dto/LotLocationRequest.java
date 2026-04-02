package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LotLocationRequest {

    private String dealerCode;
    private String locationCode;
    private String locationDesc;
    private String locationType;
    private Short maxCapacity;
    private String activeFlag;
}
