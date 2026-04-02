package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SnapshotCaptureRequest {

    private String dealerCode;
    private LocalDate snapshotDate;
}
