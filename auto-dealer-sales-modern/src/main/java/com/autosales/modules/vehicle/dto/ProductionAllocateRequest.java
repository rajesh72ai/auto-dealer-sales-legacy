package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductionAllocateRequest {

    private String allocatedDealer;
    private String priority;
}
