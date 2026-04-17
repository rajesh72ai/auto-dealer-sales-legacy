package com.autosales.modules.agent;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.List;
import java.util.Map;

import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

@Component
public class OpenClawClient {

    private static final Logger log = LoggerFactory.getLogger(OpenClawClient.class);

    private final RestClient restClient;
    // What we send to the gateway as "model". OpenClaw's /v1 endpoint requires
    // "openclaw" or "openclaw/<agentId>" — it routes to the real provider model
    // via agents.defaults.model.primary in openclaw.json.
    private static final String GATEWAY_MODEL = "openclaw";
    // What we report in responses/logs — the actual underlying LLM.
    private final String displayModel;
    private final boolean configured;

    public OpenClawClient(@Value("${openclaw.gateway-url:}") String gatewayUrl,
                         @Value("${openclaw.gateway-token:}") String gatewayToken,
                         @Value("${claude.model:claude-sonnet-4-6}") String rawModel,
                         @Value("${agent.timeout-seconds:180}") int timeoutSeconds) {
        this.displayModel = rawModel.contains("/") ? rawModel : "anthropic/" + rawModel;
        this.configured = gatewayUrl != null && !gatewayUrl.isBlank();

        if (!this.configured) {
            log.warn("OpenClaw gateway URL not configured — agent endpoint will be unavailable");
            this.restClient = null;
            return;
        }

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) Duration.ofSeconds(10).toMillis());
        factory.setReadTimeout((int) Duration.ofSeconds(timeoutSeconds).toMillis());

        RestClient.Builder builder = RestClient.builder()
                .baseUrl(gatewayUrl)
                .requestFactory((ClientHttpRequestFactory) factory);

        if (gatewayToken != null && !gatewayToken.isBlank()) {
            builder.defaultHeader("Authorization", "Bearer " + gatewayToken);
        }

        this.restClient = builder.build();
        log.info("OpenClaw client configured: url={}, gateway-model={}, underlying-model={}",
                gatewayUrl, GATEWAY_MODEL, displayModel);
    }

    public boolean isConfigured() {
        return configured;
    }

    public String getModel() {
        return displayModel;
    }

    public CompletionResponse complete(List<Map<String, Object>> messages) {
        if (!configured) {
            throw new IllegalStateException("OpenClaw gateway is not configured");
        }

        CompletionRequest request = new CompletionRequest(GATEWAY_MODEL, messages, 4096, false);
        log.debug("Calling OpenClaw: gateway-model={}, messages={}", GATEWAY_MODEL, messages.size());

        try {
            return restClient.post()
                    .uri("/v1/chat/completions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(CompletionResponse.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            log.warn("OpenClaw rate limit: {}", e.getMessage());
            throw new AgentException("The agent is rate-limited. Please wait a moment and try again.");
        } catch (HttpClientErrorException e) {
            log.warn("OpenClaw client error {}: {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new AgentException("Agent request failed: " + e.getStatusCode());
        } catch (HttpServerErrorException e) {
            log.warn("OpenClaw server error: {}", e.getMessage());
            throw new AgentException("The agent service is temporarily unavailable. Please try again shortly.");
        } catch (Exception e) {
            log.error("OpenClaw call failed", e);
            throw new AgentException("Agent error: " + e.getMessage());
        }
    }

    // --- DTOs ---

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CompletionRequest(
            String model,
            List<Map<String, Object>> messages,
            @JsonProperty("max_tokens") int maxTokens,
            boolean stream
    ) {}

    public record CompletionResponse(List<Choice> choices, Usage usage) {}

    public record Choice(Message message, @JsonProperty("finish_reason") String finishReason) {}

    public record Message(String role, String content) {}

    public record Usage(
            @JsonProperty("prompt_tokens") int promptTokens,
            @JsonProperty("completion_tokens") int completionTokens,
            @JsonProperty("total_tokens") int totalTokens
    ) {}

    public static class AgentException extends RuntimeException {
        public AgentException(String message) { super(message); }
    }
}
