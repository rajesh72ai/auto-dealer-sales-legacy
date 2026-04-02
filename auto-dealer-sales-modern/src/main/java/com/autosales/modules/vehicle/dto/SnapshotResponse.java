package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SnapshotResponse {

    private LocalDate snapshotDate;
    private String dealerCode;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String modelDesc;
    private Short onHandCount;
    private Short inTransitCount;
    private Short onHoldCount;
    private Short avgDaysInStock;
    private BigDecimal totalValue;
}
