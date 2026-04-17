package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ExecutionResult;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.agent.action.dto.ProposalResponse;
import com.autosales.modules.agent.action.entity.AgentActionProposal;
import com.autosales.modules.agent.action.entity.AgentToolCallAudit;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * Orchestrates the three-step protocol: PROPOSE (dry-run) → CONFIRM (real execute)
 * → REJECT (user cancels). Never call handlers directly — always go through this
 * service so audit and token lifecycle stay consistent.
 */
@Service
@RequiredArgsConstructor
public class ActionService {

    private static final Logger log = LoggerFactory.getLogger(ActionService.class);

    private final ActionRegistry registry;
    private final ConfirmationTokenService tokenService;
    private final AgentToolCallAuditService auditService;
    private final CurrentUserContext userContext;
    private final ObjectMapper mapper;

    public ProposalResponse propose(String toolName, Map<String, Object> payload, String conversationId) {
        return propose(userContext.current(), toolName, payload, conversationId);
    }

    public ProposalResponse propose(CurrentUserContext.Snapshot user, String toolName,
                                    Map<String, Object> payload, String conversationId) {
        ActionHandler handler = registry.require(toolName);
        enforceRole(handler, user);
        if (payload == null) payload = Map.of();

        ImpactPreview preview;
        try {
            preview = handler.dryRun(payload, user);
        } catch (DryRunRollback rollback) {
            preview = rollback.getPreview();
        } catch (RuntimeException ex) {
            log.warn("Dry-run failed for tool={} user={}: {}", toolName, user.getUserId(), ex.getMessage());
            throw ex;
        }
        if (preview == null) {
            preview = ImpactPreview.builder()
                    .toolName(toolName)
                    .tier(handler.tier().getCode())
                    .summary("No preview available")
                    .reversible(handler.reversible())
                    .build();
        } else {
            if (preview.getToolName() == null) preview.setToolName(toolName);
            if (preview.getTier() == null) preview.setTier(handler.tier().getCode());
            preview.setReversible(handler.reversible());
        }

        AgentActionProposal proposal = tokenService.create(
                user.getUserId(), user.getDealerCode(), conversationId,
                toolName, handler.tier().getCode(), payload, preview);

        auditService.recordProposed(user, conversationId, proposal.getToken(),
                toolName, handler.tier().getCode(),
                handler.endpointDescriptor(), "POST",
                payload, preview, handler.reversible());

        return ProposalResponse.builder()
                .token(proposal.getToken())
                .toolName(toolName)
                .tier(handler.tier().getCode())
                .preview(preview)
                .expiresAt(proposal.getExpiresAt())
                .reversible(handler.reversible())
                .build();
    }

    public ExecutionResult confirm(String token) {
        return confirm(userContext.current(), token);
    }

    public ExecutionResult confirm(CurrentUserContext.Snapshot user, String token) {
        AgentActionProposal proposal = tokenService.validate(token, user.getUserId());
        ActionHandler handler = registry.require(proposal.getToolName());
        enforceRole(handler, user);

        Map<String, Object> payload = deserializePayload(proposal.getPayloadJson());
        String replayHash = ConfirmationTokenService.hash(proposal.getPayloadJson());
        if (!replayHash.equals(proposal.getPayloadHash())) {
            throw new SecurityException("Proposal payload integrity check failed");
        }

        long started = System.currentTimeMillis();
        Object result;
        AgentToolCallAudit audit;
        try {
            result = handler.execute(payload, user);
            Map<String, Object> compensation =
                    handler.reversible() ? handler.compensation(payload, result) : null;
            audit = auditService.recordExecuted(user, proposal.getConversationId(),
                    token, handler.toolName(), handler.tier().getCode(),
                    handler.endpointDescriptor(), "POST",
                    payload, result, 200,
                    System.currentTimeMillis() - started,
                    handler.reversible(), compensation);
            tokenService.markConfirmed(token, audit.getAuditId());
        } catch (RuntimeException ex) {
            auditService.recordFailed(user, proposal.getConversationId(), token,
                    handler.toolName(), handler.tier().getCode(),
                    handler.endpointDescriptor(), "POST",
                    payload, ex, System.currentTimeMillis() - started);
            tokenService.markConfirmed(token, null);
            throw ex;
        }

        return ExecutionResult.builder()
                .token(token)
                .toolName(handler.toolName())
                .status("EXECUTED")
                .result(result)
                .auditId(audit.getAuditId())
                .message("Action executed successfully")
                .reversible(handler.reversible())
                .build();
    }

    public ExecutionResult reject(String token) {
        return reject(userContext.current(), token);
    }

    public ExecutionResult reject(CurrentUserContext.Snapshot user, String token) {
        AgentActionProposal proposal = tokenService.markRejected(token, user.getUserId());
        ActionHandler handler = registry.find(proposal.getToolName()).orElse(null);
        String tier = handler != null ? handler.tier().getCode() : proposal.getTier();
        auditService.recordRejected(token, user, proposal.getToolName(), tier);
        return ExecutionResult.builder()
                .token(token)
                .toolName(proposal.getToolName())
                .status("REJECTED")
                .message("Action cancelled by user")
                .reversible(false)
                .build();
    }

    private void enforceRole(ActionHandler handler, CurrentUserContext.Snapshot user) {
        if (handler.allowedRoles() == null || handler.allowedRoles().isEmpty()) return;
        if (!handler.allowedRoles().contains(user.getRole())) {
            throw new SecurityException(
                "Your role (" + (user.getRole() != null ? user.getRole().name() : "unknown") +
                ") is not permitted to execute " + handler.toolName());
        }
    }

    private Map<String, Object> deserializePayload(String payloadJson) {
        if (payloadJson == null || payloadJson.isBlank()) return new HashMap<>();
        try {
            return mapper.readValue(payloadJson, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalStateException("Proposal payload could not be deserialized", e);
        }
    }
}
