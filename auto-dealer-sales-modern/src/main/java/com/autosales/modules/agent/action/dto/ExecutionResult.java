package com.autosales.modules.agent.action.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.time.LocalDateTime;

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

    /**
     * For successful EXECUTED responses on reversible actions, the exact
     * server-side timestamp after which Undo will fail. Kept for forensics/
     * logging; NOT used by the frontend countdown (see
     * {@link #undoWindowSeconds}). Null for non-reversible or non-executed
     * responses.
     */
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private LocalDateTime undoExpiresAt;

    /**
     * Duration in seconds the undo window is open, from THIS response.
     * Frontend computes {@code expiresAt = clientNow + undoWindowSeconds * 1000}
     * to drive the countdown — avoids timezone/clock-skew issues between
     * server and browser. Null when not reversible or not executed.
     */
    private Integer undoWindowSeconds;
}
