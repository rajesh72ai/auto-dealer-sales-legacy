package com.autosales.modules.vehicle.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransferApprovalRequest {

    private String approvedBy;
    private String notes;
}
