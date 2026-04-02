package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockReleaseRequest {

    private String reason;
    private String releaseBy;
}
