package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransitStatusResponse {

    private String vin;
    private Integer statusSeq;
    private String locationDesc;
    private String statusCode;
    private String statusName;
    private String ediRefNum;
    private LocalDateTime statusTs;
    private LocalDateTime receivedTs;
}
