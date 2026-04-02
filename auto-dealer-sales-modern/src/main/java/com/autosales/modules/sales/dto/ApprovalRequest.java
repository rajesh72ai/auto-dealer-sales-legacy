package com.autosales.modules.sales.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Request DTO for deal approval or rejection.
 * Port of SLSAPV00.cbl — sales approval transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApprovalRequest {

    @NotBlank(message = "Approver ID is required")
    @Size(max = 8)
    private String approverId;

    @NotBlank(message = "Action is required")
    @Pattern(regexp = "AP|RJ", message = "Action must be AP (Approve) or RJ (Reject)")
    private String action;

    @NotBlank(message = "Approval type is required")
    @Pattern(regexp = "MG|FN|GM", message = "Approval type must be MG (Manager), FN (Finance), or GM (General Manager)")
    private String approvalType;

    @Size(max = 200, message = "Comments cannot exceed 200 characters")
    private String comments;
}
