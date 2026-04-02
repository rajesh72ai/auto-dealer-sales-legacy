package com.autosales.modules.vehicle.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransferResponse {

    private Integer transferId;
    private String fromDealer;
    private String toDealer;
    private String vin;
    private String vehicleDesc;
    private String transferStatus;
    private String statusName;
    private String requestedBy;
    private String approvedBy;
    private LocalDateTime requestedTs;
    private LocalDateTime approvedTs;
    private LocalDateTime completedTs;
}
