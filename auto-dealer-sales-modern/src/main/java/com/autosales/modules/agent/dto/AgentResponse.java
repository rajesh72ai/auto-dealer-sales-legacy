package com.autosales.modules.agent.dto;

import com.autosales.modules.agent.action.dto.ProposalResponse;

import java.math.BigDecimal;

public record AgentResponse(
        String reply,
        String model,
        String conversationId,
        TurnUsage usage,
        ProposalResponse proposal,
        String proposalError
) {
    public AgentResponse(String reply, String model) {
        this(reply, model, null, null, null, null);
    }

    public AgentResponse(String reply, String model, String conversationId) {
        this(reply, model, conversationId, null, null, null);
    }

    public AgentResponse(String reply, String model, String conversationId, TurnUsage usage) {
        this(reply, model, conversationId, usage, null, null);
    }

    public AgentResponse(String reply, String model, String conversationId, TurnUsage usage, ProposalResponse proposal) {
        this(reply, model, conversationId, usage, proposal, null);
    }

    public record TurnUsage(
            int promptTokens,
            int completionTokens,
            int totalTokens,
            BigDecimal inputCost,
            BigDecimal outputCost,
            BigDecimal totalCost,
            String currency,
            boolean estimated
    ) {}
}
