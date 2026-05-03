package com.autosales.common.security;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "\"system_user\"")
public class SystemUser {

    @Id
    @Column(name = "user_id", length = 8)
    private String userId;

    @Column(name = "user_name", length = 60)
    private String userName;

    @Column(name = "password_hash", length = 64)
    private String passwordHash;

    @Column(name = "user_type", length = 1)
    private String userType;

    @Column(name = "dealer_code", length = 5)
    private String dealerCode;

    @Column(name = "active_flag", length = 1)
    private String activeFlag;

    @Column(name = "last_login_ts")
    private LocalDateTime lastLoginTs;

    @Column(name = "failed_attempts")
    private Integer failedAttempts;

    @Column(name = "locked_flag", length = 1)
    private String lockedFlag;

    @Column(name = "created_ts")
    private LocalDateTime createdTs;

    @Column(name = "updated_ts")
    private LocalDateTime updatedTs;

    /**
     * Per-user override of the global agent token quota. NULL means use the
     * system default ({@code agent.token-quota.daily-default}). Set to a
     * specific number to give this user a custom daily allowance.
     */
    @Column(name = "agent_daily_token_quota")
    private Integer agentDailyTokenQuota;

    /**
     * When false, the AI agent is disabled for this user — calls to the
     * agent endpoint return "Agent access disabled" without consuming any
     * quota. Default true (agent allowed).
     */
    @Column(name = "agent_enabled")
    private Boolean agentEnabled;

    /** Free-text admin note explaining the agent policy for this user. */
    @Column(name = "agent_notes", length = 200)
    private String agentNotes;
}
