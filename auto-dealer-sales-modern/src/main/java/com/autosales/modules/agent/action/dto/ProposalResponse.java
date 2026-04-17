package com.autosales.modules.agent.action.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProposalResponse {

    private String token;
    private String toolName;
    private String tier;
    private ImpactPreview preview;
    private LocalDateTime expiresAt;
    private boolean reversible;
}
