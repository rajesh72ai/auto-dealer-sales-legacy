package com.autosales.modules.agent;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

/**
 * Streaming client for the OpenClaw gateway. Uses java.net.http.HttpClient to
 * POST /v1/chat/completions with stream=true and parse the SSE response
 * line-by-line, feeding each content delta to a Consumer.
 *
 * <p>Kept separate from {@link OpenClawClient} because Spring's RestClient
 * does not lend itself to SSE consumption as cleanly.</p>
 */
@Component
public class OpenClawStreamClient {

    private static final Logger log = LoggerFactory.getLogger(OpenClawStreamClient.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final HttpClient httpClient;
    private final String gatewayUrl;
    private final String gatewayToken;
    private final boolean configured;

    public OpenClawStreamClient(@Value("${openclaw.gateway-url:}") String gatewayUrl,
                                @Value("${openclaw.gateway-token:}") String gatewayToken) {
        this.gatewayUrl = gatewayUrl;
        this.gatewayToken = gatewayToken;
        this.configured = gatewayUrl != null && !gatewayUrl.isBlank();
        this.httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public boolean isConfigured() {
        return configured;
    }

    /**
     * Stream a completion. The consumer is invoked for every text delta received.
     * Blocks until the stream is done or an error occurs.
     */
    public void streamCompletion(List<Map<String, Object>> messages,
                                 Consumer<StreamEvent> consumer) throws Exception {
        if (!configured) {
            throw new IllegalStateException("OpenClaw gateway is not configured");
        }

        ObjectNode body = MAPPER.createObjectNode();
        body.put("model", "openclaw");
        body.put("stream", true);
        body.put("max_tokens", 4096);
        body.set("messages", MAPPER.valueToTree(messages));
        // OpenAI-compatible: ask for a final chunk with usage stats
        ObjectNode streamOpts = MAPPER.createObjectNode();
        streamOpts.put("include_usage", true);
        body.set("stream_options", streamOpts);

        HttpRequest.Builder req = HttpRequest.newBuilder()
                .uri(URI.create(gatewayUrl + "/v1/chat/completions"))
                .timeout(Duration.ofMinutes(3))
                .header("Content-Type", "application/json")
                .header("Accept", "text/event-stream")
                .POST(HttpRequest.BodyPublishers.ofString(MAPPER.writeValueAsString(body)));

        if (gatewayToken != null && !gatewayToken.isBlank()) {
            req.header("Authorization", "Bearer " + gatewayToken);
        }

        HttpResponse<java.io.InputStream> response = httpClient.send(
                req.build(), HttpResponse.BodyHandlers.ofInputStream());

        if (response.statusCode() >= 400) {
            String err = new String(response.body().readAllBytes(), StandardCharsets.UTF_8);
            throw new RuntimeException("Gateway error " + response.statusCode() + ": " + err);
        }

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(response.body(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isEmpty()) continue;
                if (!line.startsWith("data:")) continue;

                String payload = line.substring(5).trim();
                if ("[DONE]".equals(payload)) {
                    consumer.accept(new StreamEvent("done", ""));
                    return;
                }
                try {
                    JsonNode root = MAPPER.readTree(payload);
                    JsonNode choices = root.path("choices");
                    if (choices.isArray() && choices.size() > 0) {
                        JsonNode delta = choices.get(0).path("delta");
                        String text = delta.path("content").asText("");
                        if (!text.isEmpty()) {
                            consumer.accept(new StreamEvent("delta", text));
                        }
                        String finishReason = choices.get(0).path("finish_reason").asText("");
                        if (!finishReason.isBlank() && !"null".equals(finishReason)) {
                            consumer.accept(new StreamEvent("finish", finishReason));
                        }
                    }
                    // Final chunk may carry usage stats (stream_options.include_usage)
                    JsonNode usage = root.path("usage");
                    if (usage.isObject() && !usage.isMissingNode()) {
                        int pt = usage.path("prompt_tokens").asInt(0);
                        int ct = usage.path("completion_tokens").asInt(0);
                        int tt = usage.path("total_tokens").asInt(pt + ct);
                        consumer.accept(new StreamEvent("usage", pt + "," + ct + "," + tt));
                    }
                } catch (Exception parseErr) {
                    log.debug("Unparseable SSE payload (skipping): {}", payload);
                }
            }
        }
    }

    public record StreamEvent(String type, String data) {}
}
