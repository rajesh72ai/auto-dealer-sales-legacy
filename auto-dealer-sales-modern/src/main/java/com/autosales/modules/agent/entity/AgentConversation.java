package com.autosales.modules.agent.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "agent_conversation")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentConversation {

    @Id
    @Column(name = "conversation_id", length = 36, nullable = false)
    private String conversationId;

    @Column(name = "user_id", length = 10, nullable = false)
    private String userId;

    @Column(name = "dealer_code", length = 5)
    private String dealerCode;

    @Column(name = "title", length = 200)
    private String title;

    @Column(name = "model", length = 80)
    private String model;

    @Column(name = "turn_count", nullable = false)
    private Integer turnCount;

    @Column(name = "token_total", nullable = false)
    private Integer tokenTotal;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (this.createdTs == null) this.createdTs = now;
        if (this.updatedTs == null) this.updatedTs = now;
        if (this.turnCount == null) this.turnCount = 0;
        if (this.tokenTotal == null) this.tokenTotal = 0;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedTs = LocalDateTime.now();
    }
}
