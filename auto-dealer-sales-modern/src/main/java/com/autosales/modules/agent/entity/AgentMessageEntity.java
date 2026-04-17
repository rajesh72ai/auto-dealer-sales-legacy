package com.autosales.modules.agent.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "agent_message")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentMessageEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "message_id")
    private Long messageId;

    @Column(name = "conversation_id", length = 36, nullable = false)
    private String conversationId;

    @Column(name = "role", length = 16, nullable = false)
    private String role;

    @Column(name = "content", columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "seq", nullable = false)
    private Integer seq;

    @Column(name = "prompt_tokens")
    private Integer promptTokens;

    @Column(name = "completion_tokens")
    private Integer completionTokens;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @PrePersist
    void onCreate() {
        if (this.createdTs == null) this.createdTs = LocalDateTime.now();
    }
}
