package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductionOrderRequest {

    private String vin;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String plantCode;
    private LocalDate buildDate;
}
