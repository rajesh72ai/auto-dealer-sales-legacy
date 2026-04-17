package com.autosales.modules.chat;

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

import java.util.*;

@Component
public class LlmClient {

    private static final Logger log = LoggerFactory.getLogger(LlmClient.class);

    private final Map<String, ProviderConfig> providers = new LinkedHashMap<>();
    private final String defaultProvider;

    public LlmClient(@Value("${groq.api-key:}") String groqKey,
                      @Value("${groq.model:llama-3.3-70b-versatile}") String groqModel,
                      @Value("${gemini.api-key:}") String geminiKey,
                      @Value("${gemini.model:gemini-2.5-flash}") String geminiModel,
                      @Value("${together.api-key:}") String togetherKey,
                      @Value("${together.model:meta-llama/Llama-3.3-70B-Instruct-Turbo}") String togetherModel,
                      @Value("${mistral.api-key:}") String mistralKey,
                      @Value("${mistral.model:mistral-small-latest}") String mistralModel,
                      @Value("${llm.default-provider:groq}") String defaultProvider) {
        this.defaultProvider = defaultProvider;

        if (groqKey != null && !groqKey.isBlank()) {
            providers.put("groq", new ProviderConfig(
                    "Groq — Llama 3.3 70B",
                    groqModel,
                    RestClient.builder()
                            .baseUrl("https://api.groq.com/openai/v1")
                            .defaultHeader("Authorization", "Bearer " + groqKey)
                            .build()
            ));
            log.info("LLM provider registered: groq ({})", groqModel);
        }

        if (geminiKey != null && !geminiKey.isBlank()) {
            providers.put("gemini", new ProviderConfig(
                    "Gemini 2.5 Flash",
                    geminiModel,
                    RestClient.builder()
                            .baseUrl("https://generativelanguage.googleapis.com/v1beta/openai")
                            .defaultHeader("Authorization", "Bearer " + geminiKey)
                            .build()
            ));
            log.info("LLM provider registered: gemini ({})", geminiModel);
        }

        if (togetherKey != null && !togetherKey.isBlank()) {
            providers.put("together", new ProviderConfig(
                    "Together — Llama 3.3 70B",
                    togetherModel,
                    RestClient.builder()
                            .baseUrl("https://api.together.xyz/v1")
                            .defaultHeader("Authorization", "Bearer " + togetherKey)
                            .build()
            ));
            log.info("LLM provider registered: together ({})", togetherModel);
        }

        if (mistralKey != null && !mistralKey.isBlank()) {
            providers.put("mistral", new ProviderConfig(
                    "Mistral Small",
                    mistralModel,
                    RestClient.builder()
                            .baseUrl("https://api.mistral.ai/v1")
                            .defaultHeader("Authorization", "Bearer " + mistralKey)
                            .build()
            ));
            log.info("LLM provider registered: mistral ({})", mistralModel);
        }

        if (providers.isEmpty()) {
            log.warn("No LLM providers configured — chat will not work");
        }
    }

    public CompletionResponse chatCompletion(String providerKey,
                                              List<Map<String, Object>> messages,
                                              List<Map<String, Object>> tools) {
        String key = (providerKey != null && providers.containsKey(providerKey))
                ? providerKey : defaultProvider;
        ProviderConfig config = providers.get(key);
        if (config == null) {
            throw new IllegalStateException("No LLM provider configured for: " + key);
        }

        var request = new CompletionRequest(config.model, messages, tools, "auto", 1024, false);
        log.debug("Calling {}: model={}, messages={}, tools={}", key, config.model, messages.size(), tools.size());

        try {
            return doPost(config.client, request);
        } catch (HttpClientErrorException.TooManyRequests e) {
            log.warn("{} rate limit hit: {}", key, e.getMessage());
            throw new RateLimitException("Rate limit reached. Please wait a moment and try again.");
        } catch (HttpClientErrorException.BadRequest e) {
            log.warn("{} bad request (retrying without tools): {}", key, e.getResponseBodyAsString());
            var retryRequest = new CompletionRequest(config.model, messages, List.of(), null, 1024, false);
            return config.client.post()
                    .uri("/chat/completions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(retryRequest)
                    .retrieve()
                    .body(CompletionResponse.class);
        } catch (HttpServerErrorException e) {
            log.warn("{} server error: {}", key, e.getMessage());
            throw new RateLimitException("The " + key + " service is temporarily unavailable. Please try another model or wait a moment.");
        }
    }

    private long parseRetryDelay(String body) {
        // Groq says: "Please try again in 12.395s" — parse the seconds
        try {
            var matcher = java.util.regex.Pattern.compile("try again in ([\\d.]+)s").matcher(body);
            if (matcher.find()) {
                double seconds = Double.parseDouble(matcher.group(1));
                return (long) (seconds * 1000) + 1000; // add 1s buffer
            }
        } catch (Exception ignored) {}
        return 20_000; // default 20s if unparseable
    }

    private CompletionResponse doPost(RestClient client, CompletionRequest request) {
        return client.post()
                .uri("/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(CompletionResponse.class);
    }

    public String getModelName(String providerKey) {
        ProviderConfig config = providers.get(providerKey);
        return config != null ? config.model : "unknown";
    }

    public List<ProviderInfo> getAvailableProviders() {
        List<ProviderInfo> list = new ArrayList<>();
        providers.forEach((key, config) -> list.add(new ProviderInfo(key, config.label, config.model)));
        return list;
    }

    public String getDefaultProvider() {
        return defaultProvider;
    }

    // --- Internal ---

    private record ProviderConfig(String label, String model, RestClient client) {}

    public record ProviderInfo(String key, String label, String model) {}

    // --- DTOs for OpenAI-compatible API ---

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CompletionRequest(
            String model,
            List<Map<String, Object>> messages,
            List<Map<String, Object>> tools,
            @JsonProperty("tool_choice") String toolChoice,
            @JsonProperty("max_tokens") int maxTokens,
            boolean stream
    ) {}

    public record CompletionResponse(
            List<Choice> choices,
            Usage usage
    ) {}

    public record Choice(
            Message message,
            @JsonProperty("finish_reason") String finishReason
    ) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record Message(
            String role,
            String content,
            @JsonProperty("tool_calls") List<ToolCall> toolCalls
    ) {}

    public record ToolCall(
            String id,
            String type,
            FunctionCall function
    ) {}

    public record FunctionCall(
            String name,
            String arguments
    ) {}

    public record Usage(
            @JsonProperty("prompt_tokens") int promptTokens,
            @JsonProperty("completion_tokens") int completionTokens,
            @JsonProperty("total_tokens") int totalTokens
    ) {}
}
