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

    /**
     * Declares the prerequisite entities this action depends on (B-prereq).
     * For example, {@code create_lead} returns a single {@link Prerequisite}
     * declaring that {@code customerId} must reference an existing customer
     * and pointing at {@code list_customers} (finder) and
     * {@code create_customer} (satisfier) so the framework can resolve gaps.
     *
     * <p>Default: empty list — most actions have no prerequisites that the
     * framework needs to chain. Override only when the action references
     * another entity that must exist or be created first.
     */
    default java.util.List<Prerequisite> prerequisites() {
        return java.util.List.of();
    }

    /**
     * A human-readable schema describing the payload this action accepts.
     * Surfaced in the Gemini system prompt so the LLM knows the exact field
     * names and constraints to gather from the user (B-prereq follow-up).
     *
     * <p>Format convention — bullet list per line, each line:
     * {@code   - fieldName (required|optional, type/format hint)}.
     *
     * <p>Without this, the LLM has to infer field shapes from prose and
     * frequently sends unstructured strings (e.g. address as one field
     * instead of addressLine1+city+stateCode+zipCode), producing avoidable
     * propose-error rejections.
     *
     * <p>Default: empty string — the framework falls back to "no schema
     * surfaced" and the LLM guesses, which is the legacy behavior.
     */
    default String payloadSchemaHint() {
        return "";
    }
}
