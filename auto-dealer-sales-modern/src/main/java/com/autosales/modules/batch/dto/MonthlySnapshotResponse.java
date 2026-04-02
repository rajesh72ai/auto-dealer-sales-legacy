package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonthlySnapshotResponse {

    private String snapshotMonth;
    private String dealerCode;
    private Short totalUnitsSold;
    private BigDecimal totalRevenue;
    private BigDecimal totalGross;
    private BigDecimal totalFiGross;
    private Short avgDaysToSell;
    private BigDecimal inventoryTurn;
    private BigDecimal fiPerDeal;
    private BigDecimal csiScore;
    private String frozenFlag;
    private LocalDateTime createdTs;
}
