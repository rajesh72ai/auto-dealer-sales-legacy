package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.autosales.modules.agent.action.repository.AgentToolCallAuditRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
                .undoExpiresAt(reversible ? LocalDateTime.now().plusSeconds(10) : null)
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
