package com.autosales.modules.agent.action;

import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ExecutionResult;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.agent.action.dto.PrerequisiteGap;
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
import java.util.List;
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
    private final PrerequisiteResolver prerequisiteResolver;
    private final com.autosales.modules.agent.AgentConversationService conversationService;

    @org.springframework.beans.factory.annotation.Value("${agent.action.undo-window-seconds:60}")
    private int undoWindowSeconds;

    public ProposalResponse propose(String toolName, Map<String, Object> payload, String conversationId) {
        return propose(userContext.current(), toolName, payload, conversationId);
    }

    public ProposalResponse propose(CurrentUserContext.Snapshot user, String toolName,
                                    Map<String, Object> payload, String conversationId) {
        ActionHandler handler = registry.require(toolName);
        enforceRole(handler, user);
        if (payload == null) payload = Map.of();

        // B-prereq: short-circuit if the action has unmet prerequisites the
        // framework can resolve. We don't run the dry-run yet (it would fail
        // with a confusing validation error); instead we return a structured
        // gap envelope so the frontend can collect the missing data and
        // chain the satisfier action(s) before retrying the parent.
        PrerequisiteGap gap = prerequisiteResolver.analyze(handler, payload);
        if (gap != null) {
            log.info("Prereq gap on {}: {} unmet field(s) — returning gap envelope",
                    toolName, gap.getUnmet().size());
            return ProposalResponse.builder()
                    .toolName(toolName)
                    .tier(handler.tier().getCode())
                    .reversible(handler.reversible())
                    .prerequisiteGap(gap)
                    .build();
        }

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

    /**
     * Per-conversation hygiene called at the start of each turn. Marks any
     * PENDING proposals whose TTL has elapsed as EXPIRED and persists a
     * system note so the LLM's next replay carries an explicit cancellation
     * signal.
     *
     * <p>Without this, Gemini sees a half-finished workflow in conversation
     * history and re-emits the abandoned proposal alongside the next turn's
     * actual answer. Observed live in conv b928d43e on 2026-05-04: a
     * create_customer PROPOSE for "Shaneesh Nanu" sat unconfirmed for ~10
     * minutes, then resurfaced when the user asked an unrelated list_leads
     * question — the model added a fresh propose for the same payload
     * because the conversation context implied the workflow was incomplete.
     *
     * @return number of proposals just transitioned to EXPIRED (0 = no-op)
     */
    public int expireStaleForConversationAndAnnotate(String conversationId) {
        if (conversationId == null || conversationId.isBlank()) return 0;
        List<AgentActionProposal> stale = tokenService.expireStaleForConversation(conversationId);
        if (stale.isEmpty()) return 0;
        conversationService.appendSystemNote(conversationId, buildExpiredProposalNote(stale));
        log.info("Expired {} stale proposal(s) in conv {}; cancellation note injected",
                stale.size(), conversationId);
        return stale.size();
    }

    private String buildExpiredProposalNote(List<AgentActionProposal> stale) {
        StringBuilder note = new StringBuilder("Cancellation signal — ");
        if (stale.size() == 1) {
            note.append("the prior ").append(stale.get(0).getToolName())
                .append(" proposal expired without confirmation; the user moved on. ");
        } else {
            note.append(stale.size()).append(" prior proposals expired without confirmation (");
            for (int i = 0; i < stale.size(); i++) {
                if (i > 0) note.append(", ");
                note.append(stale.get(i).getToolName());
            }
            note.append("); the user moved on. ");
        }
        note.append("Do NOT re-propose these workflows unless the current user message explicitly asks for them again.");
        return note.toString();
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

            // B-prereq follow-up: inject the action result back into the
            // conversation so subsequent agent turns "remember" what the user
            // just confirmed. Without this, the agent doesn't know the new
            // entity exists and would propose a duplicate (verified live
            // 2026-05-03 with create_customer for Jane Smith).
            if (proposal.getConversationId() != null && conversationService != null) {
                try {
                    String note = formatActionResultNote(handler.toolName(), result, audit.getAuditId());
                    conversationService.appendSystemNote(proposal.getConversationId(), note);
                } catch (Exception noteErr) {
                    log.warn("Failed to inject action-result note for audit {}: {}",
                            audit.getAuditId(), noteErr.getMessage());
                }
            }
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
                .undoExpiresAt(audit.getUndoExpiresAt())
                .undoWindowSeconds(handler.reversible() ? undoWindowSeconds : null)
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

    /**
     * Build a one-line system note summarizing what the user just confirmed.
     * Format: "[Action confirmed: <tool> succeeded. Result: <key fields>. Audit ID <n>.]"
     * Goes into the conversation as role=system so the LLM treats it as
     * authoritative ground truth on subsequent turns.
     */
    private String formatActionResultNote(String toolName, Object result, Long auditId) {
        StringBuilder sb = new StringBuilder("[Action confirmed: ").append(toolName)
                .append(" succeeded. ");
        if (result != null) {
            try {
                String json = mapper.writeValueAsString(result);
                if (json.length() > 600) json = json.substring(0, 600) + "…";
                sb.append("Result: ").append(json).append(". ");
            } catch (Exception ignore) {
                sb.append("Result available. ");
            }
        }
        sb.append("Audit ID ").append(auditId)
          .append(". This entity is now in the system; reference it by id in future actions.]");
        return sb.toString();
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
