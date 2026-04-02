package com.autosales.modules.floorplan.dto;

import lombok.*;

import java.math.BigDecimal;

/**
 * Floor plan lender detail response with computed effective rate.
 * Port of FPLND00.cbl — floor plan lender inquiry transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanLenderResponse {

    private String lenderId;
    private String lenderName;
    private String contactName;
    private String phone;

    private BigDecimal baseRate;
    private BigDecimal spread;
    private BigDecimal effectiveRate;   // computed: baseRate + spread

    private Integer curtailmentDays;
    private Integer freeFloorDays;
}
