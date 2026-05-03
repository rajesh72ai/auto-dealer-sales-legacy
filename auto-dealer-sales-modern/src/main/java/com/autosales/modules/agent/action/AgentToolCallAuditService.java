package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.autosales.modules.agent.action.repository.AgentToolCallAuditRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AgentToolCallAuditService {

    public enum Status { PROPOSED, CONFIRMED, REJECTED, EXECUTED, FAILED }

    private static final Logger log = LoggerFactory.getLogger(AgentToolCallAuditService.class);

    private final AgentToolCallAuditRepository repo;
    private final ObjectMapper mapper;

    @Value("${agent.action.undo-window-seconds:60}")
    private long undoWindowSeconds;

    @Transactional
    public AgentToolCallAudit recordProposed(CurrentUserContext.Snapshot user, String conversationId,
                                             String proposalToken, String toolName, String tier,
                                             String endpoint, String method,
                                             Object payload, Object preview, boolean reversible) {
        AgentToolCallAudit a = AgentToolCallAudit.builder()
                .userId(user.getUserId())
                .userRole(user.roleCode())
                .dealerCode(user.getDealerCode())
                .conversationId(conversationId)
                .proposalToken(proposalToken)
                .toolName(toolName)
                .tier(tier)
                .endpoint(endpoint)
                .httpMethod(method)
                .payloadJson(toJson(payload))
                .previewJson(toJson(preview))
                .status(Status.PROPOSED.name())
                .dryRun(true)
                .reversible(reversible)
                .undone(false)
                .build();
        return repo.save(a);
    }

    @Transactional
    public AgentToolCallAudit recordExecuted(CurrentUserContext.Snapshot user, String conversationId,
                                             String proposalToken, String toolName, String tier,
                                             String endpoint, String method,
                                             Object payload, Object response,
                                             int httpStatus, long elapsedMs,
                                             boolean reversible, Object compensation) {
        AgentToolCallAudit a = AgentToolCallAudit.builder()
                .userId(user.getUserId())
                .userRole(user.roleCode())
                .dealerCode(user.getDealerCode())
                .conversationId(conversationId)
                .proposalToken(proposalToken)
                .toolName(toolName)
                .tier(tier)
                .endpoint(endpoint)
                .httpMethod(method)
                .payloadJson(toJson(payload))
                .responseJson(toJson(response))
                .status(Status.EXECUTED.name())
                .httpStatus(httpStatus)
                .elapsedMs((int) Math.min(elapsedMs, Integer.MAX_VALUE))
                .dryRun(false)
                .reversible(reversible)
                .compensationJson(compensation != null ? toJson(compensation) : null)
                .undoExpiresAt(reversible ? LocalDateTime.now().plusSeconds(undoWindowSeconds) : null)
                .undone(false)
                .build();
        return repo.save(a);
    }

    @Transactional
    public AgentToolCallAudit recordFailed(CurrentUserContext.Snapshot user, String conversationId,
                                           String proposalToken, String toolName, String tier,
                                           String endpoint, String method,
                                           Object payload, Throwable error, long elapsedMs) {
        AgentToolCallAudit a = AgentToolCallAudit.builder()
                .userId(user.getUserId())
                .userRole(user.roleCode())
                .dealerCode(user.getDealerCode())
                .conversationId(conversationId)
                .proposalToken(proposalToken)
                .toolName(toolName)
                .tier(tier)
                .endpoint(endpoint)
                .httpMethod(method)
                .payloadJson(toJson(payload))
                .status(Status.FAILED.name())
                .errorMessage(truncate(error.getMessage(), 500))
                .elapsedMs((int) Math.min(elapsedMs, Integer.MAX_VALUE))
                .dryRun(false)
                .reversible(false)
                .undone(false)
                .build();
        return repo.save(a);
    }

    @Transactional
    public void recordRejected(String proposalToken, CurrentUserContext.Snapshot user,
                               String toolName, String tier) {
        AgentToolCallAudit a = AgentToolCallAudit.builder()
                .userId(user.getUserId())
                .userRole(user.roleCode())
                .dealerCode(user.getDealerCode())
                .proposalToken(proposalToken)
                .toolName(toolName)
                .tier(tier)
                .status(Status.REJECTED.name())
                .dryRun(true)
                .reversible(false)
                .undone(false)
                .build();
        repo.save(a);
    }

    /**
     * Records a read-only tool call (e.g., {@code list_deals}, {@code get_stock_aging})
     * invoked by an agent during its function-calling loop. These do not flow through
     * the propose/confirm framework — they're side-effect-free queries — but we still
     * persist them so the admin trace UI can show the full tool-call timeline per
     * conversation, and so analytics (tool-call frequency, latency p50/p95) can be
     * computed downstream (B3b).
     *
     * <p>Tier is fixed to "R" (READ) and {@code proposal_token} is null since these
     * calls don't go through the propose/confirm protocol.
     */
    @Transactional
    public AgentToolCallAudit recordReadToolCall(CurrentUserContext.Snapshot user,
                                                 String conversationId,
                                                 String toolName,
                                                 Object args,
                                                 Object result,
                                                 long elapsedMs,
                                                 boolean errored) {
        AgentToolCallAudit a = AgentToolCallAudit.builder()
                .userId(user != null ? user.getUserId() : "anonymous")
                .userRole(user != null ? user.roleCode() : null)
                .dealerCode(user != null ? user.getDealerCode() : null)
                .conversationId(conversationId)
                .toolName(toolName)
                .tier("R")
                .payloadJson(toJson(args))
                .responseJson(toJson(result))
                .status(errored ? Status.FAILED.name() : Status.EXECUTED.name())
                .httpStatus(errored ? 500 : 200)
                .elapsedMs((int) Math.min(elapsedMs, Integer.MAX_VALUE))
                .dryRun(false)
                .reversible(false)
                .undone(false)
                .build();
        return repo.save(a);
    }

    private String toJson(Object o) {
        if (o == null) return null;
        try {
            return mapper.writeValueAsString(o);
        } catch (JsonProcessingException e) {
            log.warn("Could not serialize audit payload: {}", e.getMessage());
            return "{\"_serializationError\":\"" + e.getMessage() + "\"}";
        }
    }

    private String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }
}
