package com.autosales.modules.registration.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecallVehicleResponse {

    private String recallId;
    private String vin;
    private String dealerCode;
    private String recallStatus;
    private LocalDate notifiedDate;
    private LocalDate scheduledDate;
    private LocalDate completedDate;
    private String technicianId;
    private String partsOrdered;
    private String partsAvail;

    // Computed fields
    private String recallStatusName;
}
