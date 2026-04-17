package com.autosales.modules.agent.action.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "agent_action_proposal")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentActionProposal {

    @Id
    @Column(name = "token", length = 36, nullable = false)
    private String token;

    @Column(name = "user_id", length = 20, nullable = false)
    private String userId;

    @Column(name = "dealer_code", length = 10)
    private String dealerCode;

    @Column(name = "conversation_id", length = 36)
    private String conversationId;

    @Column(name = "tool_name", length = 64, nullable = false)
    private String toolName;

    @Column(name = "tier", length = 1, nullable = false)
    private String tier;

    @Column(name = "payload_json", columnDefinition = "TEXT", nullable = false)
    private String payloadJson;

    @Column(name = "payload_hash", length = 64, nullable = false)
    private String payloadHash;

    @Column(name = "preview_json", columnDefinition = "TEXT", nullable = false)
    private String previewJson;

    @Column(name = "status", length = 20, nullable = false)
    private String status;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "decided_at")
    private LocalDateTime decidedAt;

    @Column(name = "execution_audit_id")
    private Long executionAuditId;

    public enum Status { PENDING, CONFIRMED, REJECTED, EXPIRED }

    @PrePersist
    void onCreate() {
        if (this.createdTs == null) this.createdTs = LocalDateTime.now();
        if (this.status == null) this.status = Status.PENDING.name();
    }
}
