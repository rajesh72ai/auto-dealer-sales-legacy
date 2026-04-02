package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransitStatusRequest {

    private String vin;
    private String locationDesc;
    private String statusCode;
    private String ediRefNum;
}
