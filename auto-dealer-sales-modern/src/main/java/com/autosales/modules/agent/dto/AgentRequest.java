package com.autosales.modules.agent.dto;

import java.util.List;

/**
 * Two modes:
 *   1) Legacy — caller supplies the full {@code messages} array; server does not persist.
 *   2) Persistent — caller supplies {@code conversationId} (may be null to start a new one)
 *      and a single {@code userMessage}; server reconstructs history from DB and saves both turns.
 *
 * When {@code userMessage} is non-null, persistent mode wins.
 */
public record AgentRequest(
        List<Message> messages,
        String model,
        String conversationId,
        String userMessage
) {
    public record Message(String role, String content) {}
}
