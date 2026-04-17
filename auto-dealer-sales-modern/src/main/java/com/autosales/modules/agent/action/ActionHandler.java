package com.autosales.modules.agent.action;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.dto.ImpactPreview;

import java.util.Map;
import java.util.Set;

/**
 * A write-capable agent tool. Each handler is registered as a Spring bean
 * and auto-discovered by {@link ActionRegistry}. Handlers MUST support dry-run
 * preview before execute; execute() is only reached via a valid confirmation
 * token, never directly from the agent.
 */
public interface ActionHandler {

    String toolName();

    Tier tier();

    Set<UserRole> allowedRoles();

    /**
     * Human-readable endpoint path logged in audit (e.g. "POST /api/deals").
     */
    String endpointDescriptor();

    /**
     * Build a preview of what execute() would do, WITHOUT persisting. Must
     * either use transactional rollback or compute purely read-side.
     */
    ImpactPreview dryRun(Map<String, Object> payload, CurrentUserContext.Snapshot user);

    /**
     * Commit the mutation. Only called after a proposal has been confirmed.
     * Return whatever the downstream service returns; framework will serialize
     * it into the audit row and user-visible result.
     */
    Object execute(Map<String, Object> payload, CurrentUserContext.Snapshot user);

    /**
     * True if this tool can be undone — structural scaffolding for a future
     * Mobile-style undo window. Handler may return a non-null compensation plan
     * from {@link #compensation(Map, Object)} when reversible is true.
     */
    default boolean reversible() { return false; }

    /**
     * Serializable description of the inverse action. v1 stores this for audit
     * completeness; the UndoService consumer is stubbed and will not execute it.
     */
    default Map<String, Object> compensation(Map<String, Object> payload, Object executeResult) {
        return null;
    }
}
