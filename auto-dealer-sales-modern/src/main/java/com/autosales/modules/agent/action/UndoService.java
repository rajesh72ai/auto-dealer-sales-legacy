package com.autosales.modules.agent.action;

import org.springframework.stereotype.Service;

/**
 * Scaffolding for the future Mobile-style "Undo (10s)" window on reversible
 * Tier A/B actions. Structure is present so activation is additive, not a refactor.
 *
 * v1 policy (2026-04-16): NOT ACTIVATED. Audit rows carry compensation_json and
 * undo_expires_at, but this service refuses to execute them.
 *
 * To activate:
 *   1. Implement undo(auditId) to read AgentToolCallAudit, validate window, call
 *      the inverse ActionHandler.execute() and mark undone=true.
 *   2. Add POST /api/agent/actions/{auditId}/undo to ActionController.
 *   3. Add the Undo (10s) button in AgentWidget after an Executed card.
 */
@Service
public class UndoService {

    public boolean activated() {
        return false;
    }

    public Object undo(Long auditId) {
        throw new UnsupportedOperationException(
            "Undo is not activated in v1. Scaffolding only — see UndoService javadoc for activation steps.");
    }
}
