package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PdiScheduleResponse {

    private Integer pdiId;
    private String vin;
    private String vehicleDesc;
    private String dealerCode;
    private LocalDate scheduledDate;
    private String technicianId;
    private String pdiStatus;
    private String statusName;
    private Short checklistItems;
    private Short itemsPassed;
    private Short itemsFailed;
    private String notes;
    private LocalDateTime completedTs;
    private BigDecimal passRate;
}
