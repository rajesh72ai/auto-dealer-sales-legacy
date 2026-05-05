package com.autosales.eval;

import java.util.List;
import java.util.Map;

/**
 * YAML-backed prompt definition. Two shapes are supported:
 *
 * <ul>
 *   <li><b>Single-turn (legacy):</b> top-level {@code prompt} + {@code expect}.
 *       Sends one user message, observes the reply + audit trail.</li>
 *   <li><b>Multi-turn:</b> top-level {@code turns: [...]}. Each turn carries its
 *       own prompt + expect block. The driver reuses the conversationId across
 *       turns and partitions audit rows by auditId high-water mark so each
 *       turn's assertions only see that turn's tool calls.</li>
 * </ul>
 *
 * <p>The two are mutually exclusive — set one or the other, not both.
 */
public record EvalPrompt(
        String id,
        String description,
        String prompt,
        Auth auth,
        Expect expect,
        boolean flaky,
        List<Turn> turns
) {
    public record Auth(String userId, String password) {}

    /** One step in a multi-turn conversation. */
    public record Turn(String prompt, Expect expect) {}

    public record Expect(
            List<String> replyContains,
            List<String> replyNotContains,
            List<String> replyMatches,
            List<String> toolCallsInclude,
            /** Forbid these tool names from appearing in this turn's audit rows. */
            List<String> toolCallsExclude,
            /**
             * Subset match against an audit row's parsed {@code payloadJson}.
             * Map of toolName → required arg key/value pairs. Passes if at
             * least one audit row with the given toolName has a parsed
             * payload that contains every key/value in the expected map
             * (top-level keys; values compared by string equality).
             */
            Map<String, Map<String, Object>> toolCallsArgs,
            /**
             * Filter audit rows by tier before evaluating
             * {@code tool_calls_include} / {@code tool_calls_exclude} /
             * {@code tool_calls_args}. Values: {@code R} (read), {@code A}
             * (action/write proposal). When null, rows of either tier are
             * considered.
             */
            String toolCallsTier,
            Long latencyMsMax,
            Integer tokensTotalMax,
            ProposalExpect proposal
    ) {}

    /**
     * Expectations against the proposal envelope returned by /api/agent.
     *
     * <ul>
     *   <li>{@code toolName} — single expected value (back-compat, simple cases)</li>
     *   <li>{@code toolNameAnyOf} — list of acceptable values; passes if the
     *       observed proposal matches any one. Use this when the framework
     *       legitimately decomposes a chain (e.g. create_lead → create_customer
     *       as the first visible step under B-prereq).</li>
     * </ul>
     *
     * <p>If both are set, either match counts. A {@code prerequisiteGap}
     * envelope on the proposal also counts as success — the framework
     * recognized the intent and didn't drop the marker.
     */
    public record ProposalExpect(String toolName, List<String> toolNameAnyOf) {}
}
