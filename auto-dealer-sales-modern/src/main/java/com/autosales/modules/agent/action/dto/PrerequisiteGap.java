package com.autosales.modules.agent.action.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * Returned by {@code ActionService.propose} when the requested action has
 * unmet prerequisites that the framework can resolve. The frontend renders
 * a "we need a bit more info" card from this; the caller (LLM or user)
 * provides the missing data and re-proposes the chain.
 *
 * <p>One {@link PrerequisiteGap} per parent action; it can describe
 * multiple unmet prereqs. The first prereq is the natural starting point
 * for the chain (e.g. create the customer first), but the gap exposes all
 * of them so the UI can show the full plan.
 */
@Data
@Builder
public class PrerequisiteGap {
    /** The parent tool the user wanted to run (e.g. {@code "create_lead"}). */
    private String parentTool;

    /** Tier of the parent tool (A/B/C/D), for the role gate hint. */
    private String parentTier;

    /** One sentence the LLM/user can read to understand what needs to happen. */
    private String summary;

    /** Each unmet prerequisite, in suggested resolution order. */
    private List<UnmetPrereq> unmet;

    /**
     * Echoes back the original payload the user/LLM provided. The frontend
     * keeps this so when the chain completes it can re-fire the parent
     * proposal with the same data plus the resolved fields.
     */
    private Object originalPayload;

    @Data
    @Builder
    public static class UnmetPrereq {
        /** Which payload field is missing (e.g. {@code "customerId"}). */
        private String payloadField;
        /** Friendly entity name (e.g. {@code "customer"}). */
        private String entityName;
        /** Tool that can find an existing match. */
        private String finderToolName;
        /** Tool that can create the missing entity. */
        private String satisfierToolName;
        /** Field on the satisfier's result to copy back into the parent. */
        private String resultField;
        /** Hint text shown next to the input form. */
        private String userFacingHint;
        /** Field names the user should fill in. */
        private List<String> requiredUserData;
    }
}
