package com.autosales.modules.agent.catalog;

import java.util.List;

/**
 * User-facing capability descriptor — what we show in the chips, slash menu,
 * and Capability Atlas. Joins yaml-curated metadata (displayName,
 * examplePrompts, personas) with the auto-reflected backing tools/actions
 * from {@code ToolRegistry} + {@code ActionRegistry}.
 *
 * <p>The {@code displayPriority} is the per-request, persona-adjusted sort
 * order — lower wins. {@code requiresProposal} is true for any capability
 * whose backing set includes a write ActionHandler; the UI surfaces this
 * with a marker so users know to expect a confirm step.
 */
public record AgentCapability(
        String id,
        String displayName,
        String description,
        String category,
        List<String> examplePrompts,
        List<String> backedBy,
        List<String> personas,
        int demoPriority,
        boolean requiresProposal,
        int displayPriority
) {}
