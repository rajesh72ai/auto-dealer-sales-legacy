package com.autosales.modules.agent.usage;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Read-only client for Anthropic's admin usage API.
 *
 * <p>SECURITY: Uses an admin API key (sk-ant-admin-...) which has org-wide
 * authority including billing and workspace management. Key is backend-only,
 * injected via {@code ANTHROPIC_ADMIN_API_KEY} env var. NEVER logged (we redact
 * auth headers from all log output) and NEVER returned to frontend callers.</p>
 *
 * <p>Only the {@code /v1/organizations/usage_report/messages} GET endpoint is
 * exposed here. If we ever need more admin capability, add a new method and
 * review it carefully — admin keys remain active after the creator is removed.</p>
 */
@Component
public class AnthropicAdminClient {

    private static final Logger log = LoggerFactory.getLogger(AnthropicAdminClient.class);

    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .version(HttpClient.Version.HTTP_1_1)
            .build();
    private final ObjectMapper mapper;

    private final String adminKey;
    private final String baseUrl;
    private final String apiVersion;

    public AnthropicAdminClient(ObjectMapper mapper,
                                @Value("${agent.anthropic-admin.key:}") String adminKey,
                                @Value("${agent.anthropic-admin.base-url:https://api.anthropic.com}") String baseUrl,
                                @Value("${agent.anthropic-admin.api-version:2023-06-01}") String apiVersion) {
        this.mapper = mapper;
        this.adminKey = adminKey == null ? "" : adminKey.trim();
        this.baseUrl = baseUrl;
        this.apiVersion = apiVersion;
    }

    public boolean isConfigured() {
        return !adminKey.isEmpty();
    }

    /**
     * Fetch messages usage across the org. Caller provides starting_at in RFC 3339;
     * all other params are optional. Uses the max `limit` allowed for the bucket
     * width so a month's worth of data fits in one round-trip (avoids sequential
     * paginated round trips which compound latency and timeout risk).
     */
    public MessagesUsageReport fetchMessagesUsage(Instant startingAt, Instant endingAt,
                                                  String bucketWidth, List<String> groupBy) {
        if (!isConfigured()) {
            throw new IllegalStateException("Anthropic admin key not configured");
        }
        int limit = maxLimitFor(bucketWidth);
        List<MessagesUsageBucket> all = new ArrayList<>();
        String pageToken = null;
        int pagesFetched = 0;
        // Safety cap so a misconfigured call can't page forever.
        final int MAX_PAGES = 5;
        do {
            MessagesUsageReport page = fetchOnePage(startingAt, endingAt, bucketWidth, groupBy, pageToken, limit);
            if (page.data() != null) all.addAll(page.data());
            pageToken = page.hasMore() ? page.nextPage() : null;
            pagesFetched++;
        } while (pageToken != null && pagesFetched < MAX_PAGES);

        return new MessagesUsageReport(all, false, null);
    }

    /** Per Anthropic docs: 1d max 31 buckets, 1h max 168, 1m max 1440. */
    private static int maxLimitFor(String bucketWidth) {
        if ("1h".equals(bucketWidth)) return 168;
        if ("1m".equals(bucketWidth)) return 1440;
        return 31; // default and 1d
    }

    private MessagesUsageReport fetchOnePage(Instant startingAt, Instant endingAt,
                                             String bucketWidth, List<String> groupBy,
                                             String pageToken, int limit) {
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromUriString(baseUrl)
                .path("/v1/organizations/usage_report/messages")
                .queryParam("starting_at", startingAt.toString())
                .queryParam("limit", limit);
        if (endingAt != null) builder.queryParam("ending_at", endingAt.toString());
        if (bucketWidth != null && !bucketWidth.isBlank()) builder.queryParam("bucket_width", bucketWidth);
        if (groupBy != null) {
            for (String g : groupBy) builder.queryParam("group_by[]", g);
        }
        if (pageToken != null) builder.queryParam("page", pageToken);

        // build().encode() lets Spring percent-encode raw values (crucial for
        // the '[]' in group_by[] — Java's URI rejects them if left literal).
        URI uri = builder.build().encode().toUri();

        HttpRequest req = HttpRequest.newBuilder(uri)
                .header("x-api-key", adminKey)
                .header("anthropic-version", apiVersion)
                .header("Accept", "application/json")
                .timeout(Duration.ofSeconds(90))
                .GET()
                .build();

        try {
            // Redact credential when logging — note we never log adminKey itself.
            log.info("Anthropic admin usage GET {} (startingAt={} bucket={})",
                    uri.getPath(), startingAt, bucketWidth);
            HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() / 100 != 2) {
                throw new AdminApiException(
                        "Anthropic admin API returned " + resp.statusCode() + ": " + shortenBody(resp.body()));
            }
            return mapper.readValue(resp.body(), MessagesUsageReport.class);
        } catch (AdminApiException e) {
            throw e;
        } catch (Exception e) {
            throw new AdminApiException("Anthropic admin API call failed: " + e.getClass().getSimpleName()
                    + ": " + e.getMessage(), e);
        }
    }

    private static String shortenBody(String body) {
        if (body == null) return "";
        return body.length() > 500 ? body.substring(0, 500) + "…" : body;
    }

    public static class AdminApiException extends RuntimeException {
        public AdminApiException(String msg) { super(msg); }
        public AdminApiException(String msg, Throwable cause) { super(msg, cause); }
    }

    // --- Response DTOs ---------------------------------------------------

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record MessagesUsageReport(
            List<MessagesUsageBucket> data,
            @JsonProperty("has_more") boolean hasMore,
            @JsonProperty("next_page") String nextPage) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record MessagesUsageBucket(
            @JsonProperty("starting_at") String startingAt,
            @JsonProperty("ending_at")   String endingAt,
            List<MessagesUsageResult> results) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record MessagesUsageResult(
            @JsonProperty("api_key_id")              String apiKeyId,
            @JsonProperty("workspace_id")            String workspaceId,
            String model,
            @JsonProperty("service_tier")            String serviceTier,
            @JsonProperty("context_window")          String contextWindow,
            @JsonProperty("inference_geo")           String inferenceGeo,
            @JsonProperty("uncached_input_tokens")   long uncachedInputTokens,
            @JsonProperty("cache_read_input_tokens") long cacheReadInputTokens,
            @JsonProperty("cache_creation")          CacheCreation cacheCreation,
            @JsonProperty("output_tokens")           long outputTokens,
            @JsonProperty("server_tool_use")         ServerToolUse serverToolUse) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CacheCreation(
            @JsonProperty("ephemeral_1h_input_tokens") long ephemeral1hInputTokens,
            @JsonProperty("ephemeral_5m_input_tokens") long ephemeral5mInputTokens) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ServerToolUse(
            @JsonProperty("web_search_requests") long webSearchRequests) {}
}
