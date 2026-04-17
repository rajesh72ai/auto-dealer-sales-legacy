package com.autosales.modules.agent.action.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "agent_tool_call_audit")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentToolCallAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "audit_id")
    private Long auditId;

    @Column(name = "user_id", length = 20, nullable = false)
    private String userId;

    @Column(name = "user_role", length = 1)
    private String userRole;

    @Column(name = "dealer_code", length = 10)
    private String dealerCode;

    @Column(name = "conversation_id", length = 36)
    private String conversationId;

    @Column(name = "proposal_token", length = 36)
    private String proposalToken;

    @Column(name = "tool_name", length = 64, nullable = false)
    private String toolName;

    @Column(name = "tier", length = 1, nullable = false)
    private String tier;

    @Column(name = "endpoint", length = 200)
    private String endpoint;

    @Column(name = "http_method", length = 10)
    private String httpMethod;

    @Column(name = "payload_json", columnDefinition = "TEXT")
    private String payloadJson;

    @Column(name = "preview_json", columnDefinition = "TEXT")
    private String previewJson;

    @Column(name = "response_json", columnDefinition = "TEXT")
    private String responseJson;

    @Column(name = "status", length = 20, nullable = false)
    private String status;

    @Column(name = "http_status")
    private Integer httpStatus;

    @Column(name = "error_message", length = 500)
    private String errorMessage;

    @Column(name = "elapsed_ms")
    private Integer elapsedMs;

    @Column(name = "dry_run", nullable = false)
    private Boolean dryRun;

    @Column(name = "reversible", nullable = false)
    private Boolean reversible;

    @Column(name = "compensation_json", columnDefinition = "TEXT")
    private String compensationJson;

    @Column(name = "undo_expires_at")
    private LocalDateTime undoExpiresAt;

    @Column(name = "undone", nullable = false)
    private Boolean undone;

    @Column(name = "undone_at")
    private LocalDateTime undoneAt;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @PrePersist
    void onCreate() {
        if (this.createdTs == null) this.createdTs = LocalDateTime.now();
        if (this.dryRun == null) this.dryRun = false;
        if (this.reversible == null) this.reversible = false;
        if (this.undone == null) this.undone = false;
    }
}
