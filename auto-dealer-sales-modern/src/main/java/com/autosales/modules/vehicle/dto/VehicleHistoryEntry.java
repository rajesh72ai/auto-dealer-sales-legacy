package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleHistoryEntry {

    private Integer statusSeq;
    private String oldStatus;
    private String newStatus;
    private String changedBy;
    private String changeReason;
    private LocalDateTime changedTs;
}
