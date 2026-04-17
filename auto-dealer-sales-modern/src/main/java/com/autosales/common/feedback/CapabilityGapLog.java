package com.autosales.common.feedback;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Reusable entity for logging AI capability gaps.
 * Records what users asked for that the AI couldn't do,
 * along with full context for product backlog prioritization.
 */
@Entity
@Table(name = "capability_gap_log")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CapabilityGapLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "gap_id")
    private Long gapId;

    @Column(name = "app_id", length = 30, nullable = false)
    private String appId;

    @Column(name = "app_name", length = 100, nullable = false)
    private String appName;

    @Column(name = "source_system", length = 30, nullable = false)
    private String sourceSystem;

    @Column(name = "user_id", length = 20)
    private String userId;

    @Column(name = "dealer_code", length = 10)
    private String dealerCode;

    @Column(name = "requested_capability", length = 100, nullable = false)
    private String requestedCapability;

    @Column(name = "category", length = 30, nullable = false)
    private String category;

    @Column(name = "user_input", columnDefinition = "TEXT", nullable = false)
    private String userInput;

    @Column(name = "scenario_description", columnDefinition = "TEXT", nullable = false)
    private String scenarioDescription;

    @Column(name = "agent_reasoning", columnDefinition = "TEXT", nullable = false)
    private String agentReasoning;

    @Column(name = "suggested_alternative", columnDefinition = "TEXT")
    private String suggestedAlternative;

    @Column(name = "priority_hint", length = 10, nullable = false)
    private String priorityHint;

    @Column(name = "status", length = 20, nullable = false)
    private String status;

    @Column(name = "resolution_notes", columnDefinition = "TEXT")
    private String resolutionNotes;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "resolved_ts")
    private LocalDateTime resolvedTs;

    @PrePersist
    void onCreate() {
        if (this.createdTs == null) this.createdTs = LocalDateTime.now();
        if (this.appId == null) this.appId = "AUTOSALES";
        if (this.appName == null) this.appName = "Auto Dealer Sales";
        if (this.sourceSystem == null) this.sourceSystem = "AGENT";
        if (this.category == null) this.category = "UNKNOWN";
        if (this.priorityHint == null) this.priorityHint = "MEDIUM";
        if (this.status == null) this.status = "NEW";
    }
}
