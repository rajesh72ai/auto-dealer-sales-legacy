package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PdiCompleteRequest {

    private Short itemsPassed;
    private Short itemsFailed;
    private String notes;
}
