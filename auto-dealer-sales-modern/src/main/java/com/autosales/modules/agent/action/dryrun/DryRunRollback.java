package com.autosales.modules.agent.action.dryrun;

import com.autosales.modules.agent.action.dto.ImpactPreview;
import lombok.Getter;

/**
 * Thrown by a handler's dry-run path to roll back the enclosing @Transactional
 * scope after capturing state for the preview. Framework catches, extracts the
 * preview, and returns normally — no error surfaces to the caller.
 */
@Getter
public class DryRunRollback extends RuntimeException {

    private final ImpactPreview preview;

    public DryRunRollback(ImpactPreview preview) {
        super("dry-run rollback (not an error)");
        this.preview = preview;
    }
}
