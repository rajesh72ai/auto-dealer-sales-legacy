package com.autosales.modules.sales.dto;

import lombok.*;

import java.time.LocalDateTime;

/**
 * Approval result response with status transition and threshold message.
 * Port of SLSAPV00.cbl — approval result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApprovalResponse {

    private String dealNumber;
    private String approvalType;
    private String action;              // AP or RJ
    private String approverId;
    private String approverName;
    private String oldStatus;
    private String newStatus;
    private String oldStatusDescription;
    private String newStatusDescription;
    private String thresholdMessage;    // e.g., "Negative front gross requires GM approval"
    private String comments;
    private LocalDateTime approvalTs;
}
