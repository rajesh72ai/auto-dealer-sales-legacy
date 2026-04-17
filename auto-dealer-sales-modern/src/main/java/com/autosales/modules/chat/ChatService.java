package com.autosales.modules.chat;

import com.autosales.modules.chat.dto.ChatRequest;
import com.autosales.modules.chat.dto.ChatResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);
    private static final int MAX_TOOL_ROUNDS = 5;

    private static final String SYSTEM_PROMPT = """
            You are the AutoSales AI Assistant embedded in a dealer management system.
            Help dealership staff look up vehicles, customers, deals, inventory, stock, \
            floor plan, finance, registration, warranty, recalls, leads, batch jobs, \
            and run loan/lease calculations.

            CRITICAL RULES:
            - ALWAYS use the provided tools to fetch data. NEVER fabricate or guess data.
            - If a tool returns an error, tell the user what went wrong. Do not make up data.
            - Default dealer code is DLR01 unless the user specifies otherwise.
            - Be concise. Summarize data rather than dumping raw JSON.
            - Format currency with $ and commas (e.g., $35,000.00).
            - When listing records, show key fields in a readable format.
            - You CANNOT: approve/reject deals, delete records, trigger batch jobs, \
              modify inventory, or change system configuration.
            """;

    private final LlmClient llmClient;
    private final ToolRegistry toolRegistry;
    private final ToolExecutor toolExecutor;
    private final ObjectMapper objectMapper;

    public ChatService(LlmClient llmClient,
                       ToolRegistry toolRegistry,
                       ToolExecutor toolExecutor,
                       ObjectMapper objectMapper) {
        this.llmClient = llmClient;
        this.toolRegistry = toolRegistry;
        this.toolExecutor = toolExecutor;
        this.objectMapper = objectMapper;
    }

    public ChatResponse chat(ChatRequest request) {
        String provider = request.provider();

        // Build message list with system prompt
        List<Map<String, Object>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));

        for (ChatRequest.Message msg : request.messages()) {
            messages.add(Map.of("role", msg.role(), "content", msg.content()));
        }

        // Tool call loop
        for (int round = 0; round < MAX_TOOL_ROUNDS; round++) {
            LlmClient.CompletionResponse response = llmClient.chatCompletion(
                    provider, messages, toolRegistry.getToolDefinitions());

            if (response == null || response.choices() == null || response.choices().isEmpty()) {
                return new ChatResponse("Sorry, I received no response from the AI model.",
                        llmClient.getModelName(provider));
            }

            LlmClient.Message assistantMsg = response.choices().get(0).message();

            // If no tool calls, return the text response
            if (assistantMsg.toolCalls() == null || assistantMsg.toolCalls().isEmpty()) {
                String content = assistantMsg.content() != null ? assistantMsg.content() : "";
                log.info("Chat completed: provider={}, rounds={}, tokens={}", provider, round + 1,
                        response.usage() != null ? response.usage().totalTokens() : 0);
                return new ChatResponse(content, llmClient.getModelName(provider));
            }

            // Add assistant message with tool calls to conversation
            Map<String, Object> assistantEntry = new LinkedHashMap<>();
            assistantEntry.put("role", "assistant");
            assistantEntry.put("content", assistantMsg.content());

            List<Map<String, Object>> toolCallMaps = new ArrayList<>();
            for (LlmClient.ToolCall tc : assistantMsg.toolCalls()) {
                toolCallMaps.add(Map.of(
                        "id", tc.id(),
                        "type", "function",
                        "function", Map.of(
                                "name", tc.function().name(),
                                "arguments", tc.function().arguments()
                        )
                ));
            }
            assistantEntry.put("tool_calls", toolCallMaps);
            messages.add(assistantEntry);

            // Execute each tool call and add results
            for (LlmClient.ToolCall toolCall : assistantMsg.toolCalls()) {
                String toolName = toolCall.function().name();
                String argsJson = toolCall.function().arguments();

                log.debug("Executing tool: {} args={}", toolName, argsJson);
                Map<String, Object> args = parseArgs(argsJson);
                String toolResult = toolExecutor.execute(toolName, args);

                Map<String, Object> toolMessage = new LinkedHashMap<>();
                toolMessage.put("role", "tool");
                toolMessage.put("tool_call_id", toolCall.id());
                toolMessage.put("content", toolResult);
                messages.add(toolMessage);
            }

            log.debug("Tool round {} complete, continuing conversation", round + 1);
        }

        return new ChatResponse("I'm sorry, I ran into a loop processing your request. Please try rephrasing.",
                llmClient.getModelName(provider));
    }

    public List<LlmClient.ProviderInfo> getAvailableProviders() {
        return llmClient.getAvailableProviders();
    }

    public String getDefaultProvider() {
        return llmClient.getDefaultProvider();
    }

    private Map<String, Object> parseArgs(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (Exception e) {
            log.warn("Failed to parse tool args: {}", e.getMessage());
            return Map.of();
        }
    }
}
