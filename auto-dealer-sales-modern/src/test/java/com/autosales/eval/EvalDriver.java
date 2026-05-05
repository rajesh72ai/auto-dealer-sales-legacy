package com.autosales.eval;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Drives an eval prompt end-to-end against a live deploy.
 *
 * <p>Two modes:
 * <ul>
 *   <li><b>Single-turn:</b> login → POST /api/agent → fetch audit trail →
 *       evaluate assertions.</li>
 *   <li><b>Multi-turn:</b> login once, then for each turn POST /api/agent
 *       reusing the conversationId returned by the first response. After
 *       every turn we fetch the audit trail and partition rows by an
 *       auditId high-water mark so each turn's assertions only see the
 *       tool calls that turn produced.</li>
 * </ul>
 *
 * <p>Pure HTTP — does not stand up a Spring context. Targets a live deploy
 * (typically the frontend Cloud Run URL) so the test exercises the real
 * production path including JWT auth, CORS, and the nginx /api proxy.
 *
 * <p>Writes a unified markdown report at {@code target/eval-report.md} with
 * per-prompt timing, observed tool calls (per-turn for multi-turn prompts),
 * reply excerpts, and assertion failures.
 */
public class EvalDriver {

    /** Flaky prompts run up to this many times; pass threshold is majority. */
    private static final int FLAKY_ATTEMPTS = 3;
    private static final int FLAKY_PASS_THRESHOLD = 2;

    private final String targetUrl;
    private final HttpClient http;
    private final ObjectMapper json;
    private final Yaml yaml;
    private final List<Result> results = new ArrayList<>();
    private final LocalDateTime startedAt = LocalDateTime.now();

    public EvalDriver(String targetUrl) {
        this.targetUrl = targetUrl.replaceAll("/+$", "");
        this.http = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .version(HttpClient.Version.HTTP_1_1)
                .build();
        this.json = new ObjectMapper()
                .setPropertyNamingStrategy(PropertyNamingStrategies.LOWER_CAMEL_CASE)
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        this.yaml = new Yaml();
    }

    /** Load all prompts under {@code eval/prompts/} (sorted by id). */
    public List<EvalPrompt> loadCorpus(Path corpusDir) throws IOException {
        ObjectMapper yamlToRecord = new ObjectMapper()
                .setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE)
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        try (var stream = Files.list(corpusDir)) {
            return stream
                    .filter(p -> p.toString().endsWith(".yml") || p.toString().endsWith(".yaml"))
                    .sorted()
                    .map(p -> {
                        try (InputStream in = Files.newInputStream(p)) {
                            Map<String, Object> raw = yaml.load(in);
                            return yamlToRecord.convertValue(raw, EvalPrompt.class);
                        } catch (IOException e) {
                            throw new RuntimeException("Failed to read " + p, e);
                        }
                    })
                    .collect(Collectors.toList());
        }
    }

    /**
     * Run a prompt with flaky-mode retry handling. Non-flaky prompts run once;
     * flaky prompts run up to {@link #FLAKY_ATTEMPTS} times and pass if
     * {@link #FLAKY_PASS_THRESHOLD} attempts pass.
     */
    public Result run(EvalPrompt prompt) {
        if (!prompt.flaky()) {
            Result r = runOnce(prompt);
            results.add(r);
            return r;
        }
        List<Result> attempts = new ArrayList<>();
        int passes = 0;
        for (int i = 0; i < FLAKY_ATTEMPTS; i++) {
            Result r = runOnce(prompt);
            attempts.add(r);
            if (r.passed()) passes++;
        }
        // Pick the best representative attempt (last passing if any, else last)
        Result chosen = attempts.stream().filter(Result::passed).reduce((a, b) -> b)
                .orElse(attempts.get(attempts.size() - 1));
        chosen.flakyAttemptResults = attempts.stream().map(Result::passed).collect(Collectors.toList());
        if (passes >= FLAKY_PASS_THRESHOLD) {
            // Override failures — flaky majority passed
            chosen.failures.clear();
            chosen.failures.add("(flaky: " + passes + "/" + FLAKY_ATTEMPTS + " attempts passed — accepted)");
            // Make passed() see no failures by leaving failures empty after summary swap:
            chosen.flakyAccepted = true;
        }
        results.add(chosen);
        return chosen;
    }

    private Result runOnce(EvalPrompt prompt) {
        if (prompt.turns() != null && !prompt.turns().isEmpty()) {
            return runMultiTurn(prompt);
        }
        return runSingleTurn(prompt);
    }

    private Result runSingleTurn(EvalPrompt prompt) {
        long startMs = System.currentTimeMillis();
        Result r = new Result(prompt);
        try {
            String token = login(prompt.auth());
            AgentApiResponse agentResp = invokeAgent(token, prompt.prompt(), null);
            r.reply = agentResp.reply == null ? "" : agentResp.reply;
            r.conversationId = agentResp.conversationId;
            r.proposal = agentResp.proposal;
            r.proposalError = agentResp.proposalError;
            r.totalTokens = extractTotalTokens(agentResp);
            List<Map<String, Object>> rows = agentResp.conversationId == null
                    ? List.of()
                    : fetchAuditRows(token, agentResp.conversationId);
            r.auditRows = rows;
            r.toolCalls = rows.stream()
                    .map(m -> str(m.get("toolName")))
                    .filter(s -> s != null)
                    .collect(Collectors.toList());
            r.latencyMs = System.currentTimeMillis() - startMs;
            r.failures.addAll(evaluate(prompt.expect(), r.reply, r.toolCalls, r.auditRows,
                    r.totalTokens, r.latencyMs, r.proposal, r.proposalError));
        } catch (Exception e) {
            r.latencyMs = System.currentTimeMillis() - startMs;
            r.failures.add("driver error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        }
        return r;
    }

    private Result runMultiTurn(EvalPrompt prompt) {
        long startMs = System.currentTimeMillis();
        Result r = new Result(prompt);
        r.turnResults = new ArrayList<>();
        try {
            String token = login(prompt.auth());
            String conversationId = null;
            long lastSeenAuditId = 0L;
            int aggregateTokens = 0;
            for (int i = 0; i < prompt.turns().size(); i++) {
                EvalPrompt.Turn turn = prompt.turns().get(i);
                long turnStart = System.currentTimeMillis();
                AgentApiResponse agentResp = invokeAgent(token, turn.prompt(), conversationId);
                if (conversationId == null) conversationId = agentResp.conversationId;

                List<Map<String, Object>> allRows = conversationId == null
                        ? List.of()
                        : fetchAuditRows(token, conversationId);
                // Partition: only audit rows newer than the previous high-water mark
                // are this turn's. Update mark for the next turn.
                final long markForFilter = lastSeenAuditId;
                List<Map<String, Object>> turnRows = allRows.stream()
                        .filter(row -> longVal(row.get("auditId")) > markForFilter)
                        .collect(Collectors.toList());
                long maxId = turnRows.stream()
                        .mapToLong(row -> longVal(row.get("auditId")))
                        .max()
                        .orElse(lastSeenAuditId);
                lastSeenAuditId = Math.max(lastSeenAuditId, maxId);

                List<String> turnToolCalls = turnRows.stream()
                        .map(m -> str(m.get("toolName")))
                        .filter(s -> s != null)
                        .collect(Collectors.toList());

                TurnResult tr = new TurnResult();
                tr.prompt = turn.prompt();
                tr.reply = agentResp.reply == null ? "" : agentResp.reply;
                tr.toolCalls = turnToolCalls;
                tr.auditRows = turnRows;
                tr.totalTokens = extractTotalTokens(agentResp);
                tr.proposal = agentResp.proposal;
                tr.proposalError = agentResp.proposalError;
                tr.latencyMs = System.currentTimeMillis() - turnStart;
                tr.failures = evaluate(turn.expect(), tr.reply, tr.toolCalls, tr.auditRows,
                        tr.totalTokens, tr.latencyMs, tr.proposal, tr.proposalError);
                // Prefix per-turn failures with the turn index so the report is readable
                int turnIdx = i + 1;
                List<String> prefixed = tr.failures.stream()
                        .map(f -> "[turn " + turnIdx + "] " + f)
                        .collect(Collectors.toList());
                r.failures.addAll(prefixed);
                r.turnResults.add(tr);

                if (tr.totalTokens != null) aggregateTokens += tr.totalTokens;
            }
            // Roll up to single-turn fields for the table summary
            r.conversationId = conversationId;
            r.totalTokens = aggregateTokens > 0 ? aggregateTokens : null;
            if (!r.turnResults.isEmpty()) {
                TurnResult last = r.turnResults.get(r.turnResults.size() - 1);
                r.reply = last.reply;
                r.proposal = last.proposal;
                r.proposalError = last.proposalError;
            }
            r.toolCalls = r.turnResults.stream()
                    .flatMap(tr -> tr.toolCalls.stream())
                    .collect(Collectors.toList());
            r.latencyMs = System.currentTimeMillis() - startMs;
        } catch (Exception e) {
            r.latencyMs = System.currentTimeMillis() - startMs;
            r.failures.add("driver error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        }
        return r;
    }

    /** Write a single markdown report for everything {@link #run} has seen. */
    public void writeReport(Path out) throws IOException {
        Files.createDirectories(out.getParent());
        StringBuilder sb = new StringBuilder();
        sb.append("# Agent regression eval report\n\n");
        sb.append("- Run started: ").append(startedAt.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)).append("\n");
        sb.append("- Target: ").append(targetUrl).append("\n");
        long passed = results.stream().filter(Result::passed).count();
        sb.append("- Result: ").append(passed).append(" / ").append(results.size())
                .append(" passed\n\n");

        sb.append("| Prompt | Pass | Latency | Tokens | Tool calls |\n");
        sb.append("|---|---|---|---|---|\n");
        for (Result r : results) {
            String shape = r.isMultiTurn()
                    ? " _(multi-turn, " + r.turnResults.size() + " turns)_"
                    : "";
            sb.append("| `").append(r.prompt.id()).append("`").append(shape).append(" ");
            sb.append("| ").append(r.passed() ? "✅" : "❌").append(" ");
            sb.append("| ").append(r.latencyMs).append(" ms ");
            sb.append("| ").append(r.totalTokens == null ? "—" : r.totalTokens).append(" ");
            sb.append("| ").append(r.toolCalls.isEmpty() ? "_(none)_" : String.join(", ", r.toolCalls));
            sb.append(" |\n");
        }

        for (Result r : results) {
            sb.append("\n## ").append(r.passed() ? "✅" : "❌").append(" `").append(r.prompt.id()).append("`");
            if (r.isMultiTurn()) sb.append(" (multi-turn)");
            sb.append("\n\n");
            sb.append("**Description:** ").append(r.prompt.description() == null ? "—" : r.prompt.description()).append("\n\n");
            if (r.flakyAttemptResults != null) {
                sb.append("**Flaky attempts:** ");
                for (int i = 0; i < r.flakyAttemptResults.size(); i++) {
                    sb.append(r.flakyAttemptResults.get(i) ? "✅" : "❌");
                    if (i < r.flakyAttemptResults.size() - 1) sb.append(" ");
                }
                sb.append("\n\n");
            }
            if (!r.failures.isEmpty()) {
                sb.append("**Failures:**\n");
                for (String f : r.failures) sb.append("- ").append(f).append("\n");
                sb.append("\n");
            }

            if (r.isMultiTurn()) {
                for (int i = 0; i < r.turnResults.size(); i++) {
                    TurnResult tr = r.turnResults.get(i);
                    sb.append("### Turn ").append(i + 1).append("\n\n");
                    sb.append("**Prompt:** ").append(tr.prompt).append("\n\n");
                    sb.append("**Reply (excerpt):**\n\n```\n");
                    String excerpt = tr.reply == null ? "" : (tr.reply.length() > 500 ? tr.reply.substring(0, 500) + "…" : tr.reply);
                    sb.append(excerpt).append("\n```\n\n");
                    sb.append("**Tool calls observed (this turn):** ")
                            .append(tr.toolCalls.isEmpty() ? "_(none)_" : String.join(", ", tr.toolCalls)).append("\n\n");
                    if (tr.proposal != null) sb.append("**Proposal:** ").append(tr.proposal).append("\n\n");
                    if (!tr.failures.isEmpty()) {
                        sb.append("**Failures:**\n");
                        for (String f : tr.failures) sb.append("- ").append(f).append("\n");
                        sb.append("\n");
                    }
                }
            } else {
                sb.append("**Prompt:** ").append(r.prompt.prompt()).append("\n\n");
                sb.append("**Reply (excerpt):**\n\n```\n");
                String excerpt = r.reply == null ? "" : (r.reply.length() > 800 ? r.reply.substring(0, 800) + "…" : r.reply);
                sb.append(excerpt).append("\n```\n\n");
                sb.append("**Tool calls observed:** ").append(r.toolCalls.isEmpty() ? "_(none)_" : String.join(", ", r.toolCalls)).append("\n");
                if (r.proposal != null) sb.append("\n**Proposal returned:** ").append(r.proposal).append("\n");
                if (r.proposalError != null) sb.append("\n**Proposal error:** ").append(r.proposalError).append("\n");
            }
        }

        Files.writeString(out, sb.toString());
    }

    public List<Result> getResults() { return Collections.unmodifiableList(results); }

    // ---- HTTP helpers ----

    private String login(EvalPrompt.Auth auth) throws IOException, InterruptedException {
        String body = json.writeValueAsString(Map.of("userId", auth.userId(), "password", auth.password()));
        HttpResponse<String> resp = http.send(
                HttpRequest.newBuilder()
                        .uri(URI.create(targetUrl + "/api/auth/login"))
                        .header("Content-Type", "application/json")
                        .header("Origin", targetUrl)
                        .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                        .timeout(Duration.ofSeconds(20))
                        .build(),
                HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() != 200) {
            throw new RuntimeException("login failed: " + resp.statusCode() + " " + resp.body());
        }
        Map<?, ?> map = json.readValue(resp.body(), Map.class);
        Object token = map.get("accessToken");
        if (!(token instanceof String s) || s.isBlank()) {
            throw new RuntimeException("no accessToken in login response");
        }
        return s;
    }

    private AgentApiResponse invokeAgent(String token, String userMessage, String conversationId)
            throws IOException, InterruptedException {
        // Persistent mode: when conversationId is null the server creates a fresh
        // conversation; when supplied, the server replays that conversation's
        // prior messages so subsequent turns build on it. This is what enables
        // the multi-turn corpus to test cross-turn state.
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("userMessage", userMessage);
        if (conversationId != null) body.put("conversationId", conversationId);
        HttpResponse<String> resp = http.send(
                HttpRequest.newBuilder()
                        .uri(URI.create(targetUrl + "/api/agent"))
                        .header("Content-Type", "application/json")
                        .header("Authorization", "Bearer " + token)
                        .header("Origin", targetUrl)
                        .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body), StandardCharsets.UTF_8))
                        .timeout(Duration.ofSeconds(120))
                        .build(),
                HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() != 200) {
            throw new RuntimeException("agent invoke failed: " + resp.statusCode() + " " + resp.body());
        }
        return json.readValue(resp.body(), AgentApiResponse.class);
    }

    /**
     * Fetch the full audit timeline for a conversation. Returns the raw row
     * maps (not just toolName) so richer assertions
     * (tool_calls_args / tool_calls_tier) can inspect tier and payload.
     */
    private List<Map<String, Object>> fetchAuditRows(String token, String conversationId)
            throws IOException, InterruptedException {
        HttpResponse<String> resp = http.send(
                HttpRequest.newBuilder()
                        .uri(URI.create(targetUrl + "/api/admin/agent-trace/" + conversationId))
                        .header("Authorization", "Bearer " + token)
                        .header("Origin", targetUrl)
                        .GET()
                        .timeout(Duration.ofSeconds(20))
                        .build(),
                HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() != 200) {
            // Audit query failure shouldn't crash the whole run — record empty
            // and let assertions fail with a clear message.
            return List.of();
        }
        Map<?, ?> body = json.readValue(resp.body(), Map.class);
        Object rows = body.get("rows");
        if (!(rows instanceof List<?> list)) return List.of();
        List<Map<String, Object>> out = new ArrayList<>();
        for (Object row : list) {
            if (row instanceof Map<?, ?> m) {
                Map<String, Object> copy = new LinkedHashMap<>();
                for (Map.Entry<?, ?> e : m.entrySet()) {
                    copy.put(e.getKey().toString(), e.getValue());
                }
                out.add(copy);
            }
        }
        return out;
    }

    // ---- assertion engine ----

    /**
     * Evaluate one turn's expectations. {@code rows} is the audit rows scoped
     * to this turn (high-water-mark filtered for multi-turn).
     */
    private List<String> evaluate(EvalPrompt.Expect e,
                                  String reply,
                                  List<String> toolCalls,
                                  List<Map<String, Object>> rows,
                                  Integer totalTokens,
                                  long latencyMs,
                                  Map<String, Object> proposal,
                                  String proposalError) {
        List<String> failures = new ArrayList<>();
        if (e == null) return failures;

        if (e.replyContains() != null) {
            for (String s : e.replyContains()) {
                if (!reply.contains(s)) failures.add("reply_contains: missing '" + s + "'");
            }
        }
        if (e.replyNotContains() != null) {
            for (String s : e.replyNotContains()) {
                if (reply.contains(s)) failures.add("reply_not_contains: forbidden text '" + s + "' is present");
            }
        }
        if (e.replyMatches() != null) {
            for (String pat : e.replyMatches()) {
                if (!Pattern.compile(pat).matcher(reply).find()) {
                    failures.add("reply_matches: pattern /" + pat + "/ did not match");
                }
            }
        }

        // Apply tier filter ONCE for include/exclude/args — keeps the surface
        // honest (a propose-tier audit row should not satisfy a read-tool
        // assertion).
        List<Map<String, Object>> filteredRows = filterByTier(rows, e.toolCallsTier());
        List<String> filteredNames = filteredRows.stream()
                .map(m -> str(m.get("toolName")))
                .filter(s -> s != null)
                .collect(Collectors.toList());

        if (e.toolCallsInclude() != null) {
            for (String name : e.toolCallsInclude()) {
                if (!filteredNames.contains(name)) {
                    failures.add("tool_calls_include: '" + name + "' not in observed tool calls "
                            + (filteredNames.isEmpty() ? "(none)" : filteredNames)
                            + (e.toolCallsTier() != null ? " (tier=" + e.toolCallsTier() + ")" : ""));
                }
            }
        }
        if (e.toolCallsExclude() != null) {
            for (String name : e.toolCallsExclude()) {
                if (filteredNames.contains(name)) {
                    failures.add("tool_calls_exclude: forbidden tool '" + name + "' was called"
                            + (e.toolCallsTier() != null ? " (tier=" + e.toolCallsTier() + ")" : ""));
                }
            }
        }
        if (e.toolCallsArgs() != null) {
            for (Map.Entry<String, Map<String, Object>> entry : e.toolCallsArgs().entrySet()) {
                String tool = entry.getKey();
                Map<String, Object> wantArgs = entry.getValue();
                boolean matched = false;
                for (Map<String, Object> row : filteredRows) {
                    if (!tool.equals(str(row.get("toolName")))) continue;
                    Map<String, Object> parsed = parsePayload(row.get("payloadJson"));
                    if (subsetMatches(wantArgs, parsed)) {
                        matched = true;
                        break;
                    }
                }
                if (!matched) {
                    failures.add("tool_calls_args: no '" + tool + "' call had payload superset of " + wantArgs);
                }
            }
        }

        if (e.latencyMsMax() != null && latencyMs > e.latencyMsMax()) {
            failures.add("latency_ms_max: " + latencyMs + " > " + e.latencyMsMax());
        }
        if (e.tokensTotalMax() != null && totalTokens != null && totalTokens > e.tokensTotalMax()) {
            failures.add("tokens_total_max: " + totalTokens + " > " + e.tokensTotalMax());
        }
        if (e.proposal() != null) {
            // Proposal expected. Match toolName, toolNameAnyOf, OR a
            // prerequisiteGap envelope — any of those proves the framework
            // recognized the intent and didn't drop the marker.
            if (proposal == null) {
                failures.add("proposal: expected one, got null"
                        + (proposalError == null ? "" : " (proposalError=" + proposalError + ")"));
            } else {
                Object actualName = proposal.get("toolName");
                Object prereqGap = proposal.get("prerequisiteGap");
                String expectedName = e.proposal().toolName();
                List<String> anyOf = e.proposal().toolNameAnyOf();
                boolean toolNameOk = expectedName != null && expectedName.equals(actualName);
                boolean anyOfOk = anyOf != null && actualName != null && anyOf.contains(actualName.toString());
                boolean prereqOk = prereqGap != null;
                if (!toolNameOk && !anyOfOk && !prereqOk) {
                    String wanted = expectedName != null ? "toolName='" + expectedName + "'"
                            : (anyOf != null ? "toolName in " + anyOf : "any toolName");
                    failures.add("proposal: expected " + wanted
                            + " or prerequisiteGap envelope; got toolName='" + actualName + "'");
                }
            }
        } else {
            // proposal: null in YAML — assert no proposal came back.
            if (proposal != null) {
                failures.add("proposal: expected null, got toolName='" + proposal.get("toolName") + "'");
            }
        }

        return failures;
    }

    private List<Map<String, Object>> filterByTier(List<Map<String, Object>> rows, String tier) {
        if (tier == null || tier.isBlank()) return rows;
        return rows.stream()
                .filter(row -> tier.equalsIgnoreCase(str(row.get("tier"))))
                .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> parsePayload(Object payloadJson) {
        if (!(payloadJson instanceof String s) || s.isBlank()) return Map.of();
        try {
            return json.readValue(s, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            return Map.of();
        }
    }

    /**
     * True iff every key in {@code expected} is present in {@code actual} with
     * a matching value (top-level only). Values are compared by string
     * representation so YAML int/string ambiguity (e.g. {@code customerId: 14}
     * vs {@code "14"}) doesn't cause spurious failures.
     */
    private boolean subsetMatches(Map<String, Object> expected, Map<String, Object> actual) {
        if (expected == null || expected.isEmpty()) return true;
        for (Map.Entry<String, Object> exp : expected.entrySet()) {
            Object got = actual.get(exp.getKey());
            if (got == null) return false;
            if (!String.valueOf(got).equals(String.valueOf(exp.getValue()))) return false;
        }
        return true;
    }

    private static String str(Object o) { return o == null ? null : o.toString(); }
    private static long longVal(Object o) {
        if (o instanceof Number n) return n.longValue();
        if (o instanceof String s) {
            try { return Long.parseLong(s); } catch (NumberFormatException e) { return 0L; }
        }
        return 0L;
    }

    private Integer extractTotalTokens(AgentApiResponse resp) {
        if (resp.usage instanceof Map<?, ?> usage) {
            Object total = usage.get("totalTokens");
            if (total instanceof Number n) return n.intValue();
        }
        return null;
    }

    // ---- result + transport DTOs ----

    public static final class Result {
        public final EvalPrompt prompt;
        public String reply = "";
        public String conversationId;
        public List<String> toolCalls = List.of();
        public List<Map<String, Object>> auditRows = List.of();
        public long latencyMs;
        public Integer totalTokens;
        public Map<String, Object> proposal;
        public String proposalError;
        public final List<String> failures = new ArrayList<>();
        /** Populated only for multi-turn prompts. */
        public List<TurnResult> turnResults;
        /** Populated only for flaky-mode prompts (one entry per attempt). */
        public List<Boolean> flakyAttemptResults;
        /** True iff flaky majority let an otherwise-failing run pass. */
        public boolean flakyAccepted;

        Result(EvalPrompt p) { this.prompt = p; }
        public boolean isMultiTurn() { return turnResults != null && !turnResults.isEmpty(); }
        public boolean passed() {
            if (flakyAccepted) return true;
            return failures.isEmpty();
        }
        public String failureSummary() {
            if (failures.isEmpty()) return "";
            return String.join("; ", failures);
        }
    }

    /** Per-turn record for multi-turn prompts. */
    public static final class TurnResult {
        public String prompt;
        public String reply = "";
        public List<String> toolCalls = List.of();
        public List<Map<String, Object>> auditRows = List.of();
        public Integer totalTokens;
        public Map<String, Object> proposal;
        public String proposalError;
        public long latencyMs;
        public List<String> failures = new ArrayList<>();
    }

    /** Mirror of the production AgentResponse — only the fields we assert on. */
    @SuppressWarnings("unused")
    static final class AgentApiResponse {
        public String reply;
        public String model;
        public String conversationId;
        public Map<String, Object> usage;
        public Map<String, Object> proposal;
        public String proposalError;
    }
}
