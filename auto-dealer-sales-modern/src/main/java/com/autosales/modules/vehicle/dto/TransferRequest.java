package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransferRequest {

    private String fromDealer;
    private String toDealer;
    private String vin;
    private String requestedBy;
    private String reason;
}
