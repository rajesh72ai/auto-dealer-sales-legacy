package com.autosales.modules.agent.action.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExecutionResult {

    private String token;
    private String toolName;
    private String status;
    private Object result;
    private Long auditId;
    private String message;
    private boolean reversible;
}
