package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleAllocateRequest {

    private String dealNumber;
    private Integer customerId;
    private String reason;
}
