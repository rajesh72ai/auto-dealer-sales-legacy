package com.autosales.modules.agent.action.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProposeRequest {

    @NotBlank(message = "toolName is required")
    private String toolName;

    private String conversationId;

    private Map<String, Object> payload;
}
