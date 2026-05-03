package com.autosales.modules.agent.action;

import java.util.List;

/**
 * A declarative description of a precondition for executing an
 * {@link ActionHandler} — for example, "create_lead requires an existing
 * customerId."
 *
 * <p>The {@link PrerequisiteResolver} uses this to:
 * <ol>
 *   <li>Detect that a payload does not satisfy the prerequisite</li>
 *   <li>Tell the user (or LLM) what is missing in plain language</li>
 *   <li>Optionally chain a satisfying action automatically — e.g., propose
 *       a {@code create_customer} action whose result will fill the
 *       {@code customerId} field for a downstream {@code create_lead}.</li>
 * </ol>
 *
 * <p>This is the foundation of compound actions: the framework guarantees
 * every step in a chain still flows through propose / dry-run / confirm /
 * audit, so the safety properties of single-step actions extend to chains.
 *
 * @param payloadField     The payload field this prerequisite gates (e.g.
 *                         {@code "customerId"}). When the field is absent or
 *                         blank, the prerequisite is unmet.
 * @param entityName       Human-readable name of the missing entity (e.g.
 *                         {@code "customer"}). Surfaces in the UI.
 * @param finderToolName   Read tool that can find an existing match (e.g.
 *                         {@code "list_customers"}). May be null when no
 *                         finder exists.
 * @param satisfierToolName Write tool that can create the missing entity
 *                         (e.g. {@code "create_customer"}). May be null when
 *                         no satisfier exists in this app — in which case
 *                         the framework declines the parent action.
 * @param resultField      Field on the satisfier's execute() result that
 *                         carries the value to fill into the parent
 *                         payload's {@code payloadField} (e.g.
 *                         {@code "customerId"} on the new CustomerResponse).
 * @param userFacingHint   One-sentence prose hint to show alongside the gap
 *                         card (e.g. "Provide name + address for the new
 *                         customer record.").
 * @param requiredUserData Field names the user must supply to satisfy the
 *                         prerequisite (used by the gap card to render an
 *                         input form). Order is preserved for display.
 */
public record Prerequisite(
        String payloadField,
        String entityName,
        String finderToolName,
        String satisfierToolName,
        String resultField,
        String userFacingHint,
        List<String> requiredUserData
) {
    public Prerequisite {
        if (payloadField == null || payloadField.isBlank()) {
            throw new IllegalArgumentException("payloadField is required");
        }
        if (entityName == null) entityName = payloadField;
        if (requiredUserData == null) requiredUserData = List.of();
    }
}
