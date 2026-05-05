package com.autosales.eval;

import java.util.List;

public record EvalPrompt(
        String id,
        String description,
        String prompt,
        Auth auth,
        Expect expect,
        boolean flaky
) {
    public record Auth(String userId, String password) {}

    public record Expect(
            List<String> replyContains,
            List<String> replyNotContains,
            List<String> replyMatches,
            List<String> toolCallsInclude,
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
