package com.autosales.modules.floorplan.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Floor plan payoff result response with final interest and total payoff amount.
 * Port of FPPAY00.cbl — floor plan payoff result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanPayoffResponse {

    private String vin;
    private Integer floorPlanId;
    private String lenderId;
    private LocalDate originalFloorDate;
    private LocalDate payoffDate;
    private BigDecimal originalBalance;
    private BigDecimal finalInterest;
    private BigDecimal totalPayoff;
    private Integer daysOnFloor;
    private String status;              // PD (Paid)
}
