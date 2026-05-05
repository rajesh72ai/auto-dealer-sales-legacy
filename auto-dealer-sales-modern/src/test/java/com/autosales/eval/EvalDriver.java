package com.autosales.eval;

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
 * Drives a single eval prompt end-to-end: login → POST /api/agent → fetch the
 * tool-call audit trail → evaluate assertions → return a {@link Result}.
 *
 * <p>Pure HTTP — does not stand up a Spring context. Targets a live deploy
 * (typically the frontend Cloud Run URL) so the test exercises the real
 * production path including JWT auth, CORS, and the nginx /api proxy.
 *
 * <p>The driver is also responsible for writing {@code target/eval-report.md}
 * — a single markdown file summarizing every prompt run in the session, with
 * per-prompt timing, observed tool calls, and a per-assertion breakdown for
 * any failures. Designed to paste directly into a PR description.
 */
public class EvalDriver {

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

    public Result run(EvalPrompt prompt) {
        long startMs = System.currentTimeMillis();
        Result r = new Result(prompt);
        try {
            String token = login(prompt.auth());
            AgentApiResponse agentResp = invokeAgent(token, prompt.prompt());
            r.reply = agentResp.reply == null ? "" : agentResp.reply;
            r.conversationId = agentResp.conversationId;
            r.proposal = agentResp.proposal;
            r.proposalError = agentResp.proposalError;
            if (agentResp.usage instanceof Map<?, ?> usage) {
                Object total = usage.get("totalTokens");
                if (total instanceof Number n) r.totalTokens = n.intValue();
            }
            r.toolCalls = agentResp.conversationId == null
                    ? List.of()
                    : fetchToolCalls(token, agentResp.conversationId);
            r.latencyMs = System.currentTimeMillis() - startMs;
            r.failures.addAll(evaluate(prompt, r));
        } catch (Exception e) {
            r.latencyMs = System.currentTimeMillis() - startMs;
            r.failures.add("driver error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        }
        results.add(r);
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
            sb.append("| `").append(r.prompt.id()).append("` ");
            sb.append("| ").append(r.passed() ? "✅" : "❌").append(" ");
            sb.append("| ").append(r.latencyMs).append(" ms ");
            sb.append("| ").append(r.totalTokens == null ? "—" : r.totalTokens).append(" ");
            sb.append("| ").append(r.toolCalls.isEmpty() ? "_(none)_" : String.join(", ", r.toolCalls));
            sb.append(" |\n");
        }

        for (Result r : results) {
            sb.append("\n## ").append(r.passed() ? "✅" : "❌").append(" `").append(r.prompt.id()).append("`\n\n");
            sb.append("**Description:** ").append(r.prompt.description() == null ? "—" : r.prompt.description()).append("\n\n");
            sb.append("**Prompt:** ").append(r.prompt.prompt()).append("\n\n");
            if (!r.failures.isEmpty()) {
                sb.append("**Failures:**\n");
                for (String f : r.failures) sb.append("- ").append(f).append("\n");
                sb.append("\n");
            }
            sb.append("**Reply (excerpt):**\n\n```\n");
            String excerpt = r.reply == null ? "" : (r.reply.length() > 800 ? r.reply.substring(0, 800) + "…" : r.reply);
            sb.append(excerpt).append("\n```\n\n");
            sb.append("**Tool calls observed:** ").append(r.toolCalls.isEmpty() ? "_(none)_" : String.join(", ", r.toolCalls)).append("\n");
            if (r.proposal != null) sb.append("\n**Proposal returned:** ").append(r.proposal).append("\n");
            if (r.proposalError != null) sb.append("\n**Proposal error:** ").append(r.proposalError).append("\n");
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

    private AgentApiResponse invokeAgent(String token, String userMessage) throws IOException, InterruptedException {
        // Persistent mode (conversationId=null + userMessage set) so the
        // server creates a fresh conversation we can audit-query afterwards.
        String body = json.writeValueAsString(Map.of("userMessage", userMessage));
        HttpResponse<String> resp = http.send(
                HttpRequest.newBuilder()
                        .uri(URI.create(targetUrl + "/api/agent"))
                        .header("Content-Type", "application/json")
                        .header("Authorization", "Bearer " + token)
                        .header("Origin", targetUrl)
                        .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                        .timeout(Duration.ofSeconds(120))
                        .build(),
                HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() != 200) {
            throw new RuntimeException("agent invoke failed: " + resp.statusCode() + " " + resp.body());
        }
        return json.readValue(resp.body(), AgentApiResponse.class);
    }

    private List<String> fetchToolCalls(String token, String conversationId) throws IOException, InterruptedException {
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
            // Audit query failure shouldn't crash the whole run — record
            // empty list and let assertions fail with a clear message.
            return List.of();
        }
        Map<?, ?> body = json.readValue(resp.body(), Map.class);
        Object rows = body.get("rows");
        if (!(rows instanceof List<?> list)) return List.of();
        List<String> out = new ArrayList<>();
        for (Object row : list) {
            if (row instanceof Map<?, ?> m) {
                Object tn = m.get("toolName");
                if (tn instanceof String s) out.add(s);
            }
        }
        return out;
    }

    // ---- assertion engine ----

    private List<String> evaluate(EvalPrompt p, Result r) {
        List<String> failures = new ArrayList<>();
        EvalPrompt.Expect e = p.expect();
        if (e == null) return failures;

        if (e.replyContains() != null) {
            for (String s : e.replyContains()) {
                if (!r.reply.contains(s)) {
                    failures.add("reply_contains: missing '" + s + "'");
                }
            }
        }
        if (e.replyNotContains() != null) {
            for (String s : e.replyNotContains()) {
                if (r.reply.contains(s)) {
                    failures.add("reply_not_contains: forbidden text '" + s + "' is present");
                }
            }
        }
        if (e.replyMatches() != null) {
            for (String pat : e.replyMatches()) {
                if (!Pattern.compile(pat).matcher(r.reply).find()) {
                    failures.add("reply_matches: pattern /" + pat + "/ did not match");
                }
            }
        }
        if (e.toolCallsInclude() != null) {
            for (String name : e.toolCallsInclude()) {
                if (!r.toolCalls.contains(name)) {
                    failures.add("tool_calls_include: '" + name + "' not in observed tool calls "
                            + (r.toolCalls.isEmpty() ? "(none)" : r.toolCalls));
                }
            }
        }
        if (e.latencyMsMax() != null && r.latencyMs > e.latencyMsMax()) {
            failures.add("latency_ms_max: " + r.latencyMs + " > " + e.latencyMsMax());
        }
        if (e.tokensTotalMax() != null && r.totalTokens != null && r.totalTokens > e.tokensTotalMax()) {
            failures.add("tokens_total_max: " + r.totalTokens + " > " + e.tokensTotalMax());
        }
        if (e.proposal() != null) {
            // Proposal is expected. Either a clean proposal with matching
            // toolName, OR a prerequisiteGap for the same parent action,
            // counts as success — both prove the framework recognized the
            // intent and didn't silently drop the marker.
            if (r.proposal == null) {
                failures.add("proposal: expected one, got null"
                        + (r.proposalError == null ? "" : " (proposalError=" + r.proposalError + ")"));
            } else {
                Object actualName = r.proposal.get("toolName");
                Object prereqGap = r.proposal.get("prerequisiteGap");
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
            if (r.proposal != null) {
                failures.add("proposal: expected null, got toolName='" + r.proposal.get("toolName") + "'");
            }
        }

        return failures;
    }

    // ---- result + transport DTOs ----

    public static final class Result {
        public final EvalPrompt prompt;
        public String reply = "";
        public String conversationId;
        public List<String> toolCalls = List.of();
        public long latencyMs;
        public Integer totalTokens;
        public Map<String, Object> proposal;
        public String proposalError;
        public final List<String> failures = new ArrayList<>();

        Result(EvalPrompt p) { this.prompt = p; }
        public boolean passed() { return failures.isEmpty(); }
        public String failureSummary() {
            if (failures.isEmpty()) return "";
            return String.join("; ", failures);
        }
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

    @SuppressWarnings("unused")
    private static String preview(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max) + "…";
    }

    @SuppressWarnings("unused")
    private static Map<String, Object> linked(Map<String, Object> m) {
        return m == null ? new LinkedHashMap<>() : new LinkedHashMap<>(m);
    }
}
