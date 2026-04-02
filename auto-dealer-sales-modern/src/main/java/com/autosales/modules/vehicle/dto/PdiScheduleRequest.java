package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PdiScheduleRequest {

    private String vin;
    private String dealerCode;
    private LocalDate scheduledDate;
    private String technicianId;
}
