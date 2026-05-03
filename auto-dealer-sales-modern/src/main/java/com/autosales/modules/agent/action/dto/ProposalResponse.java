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

    /**
     * When non-null, the proposal could not be created because the action has
     * unmet prerequisites the framework knows how to resolve. The frontend
     * renders this as a "we need a bit more info" card with inline form fields
     * and chains the satisfier action(s) before retrying the parent. When
     * present, all the other fields above are null. (B-prereq.)
     */
    private PrerequisiteGap prerequisiteGap;
}
