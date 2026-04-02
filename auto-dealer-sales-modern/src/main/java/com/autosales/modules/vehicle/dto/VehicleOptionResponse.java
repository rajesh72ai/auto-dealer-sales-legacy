package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleOptionResponse {

    private String optionCode;
    private String optionDesc;
    private BigDecimal optionPrice;
    private String installedFlag;
}
