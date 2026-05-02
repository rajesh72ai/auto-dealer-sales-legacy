package com.autosales.modules.gemini;

import com.autosales.modules.chat.ToolExecutor;
import com.google.cloud.vertexai.VertexAI;
import com.google.cloud.vertexai.api.Content;
import com.google.cloud.vertexai.api.FunctionCall;
import com.google.cloud.vertexai.api.FunctionResponse;
import com.google.cloud.vertexai.api.GenerateContentResponse;
import com.google.cloud.vertexai.api.Part;
import com.google.cloud.vertexai.api.Tool;
import com.google.cloud.vertexai.generativeai.GenerativeModel;
import com.google.cloud.vertexai.generativeai.ResponseHandler;
import com.google.protobuf.Struct;
// NOTE: Don't `import com.google.protobuf.Value` — it would clash with
// Spring's `org.springframework.beans.factory.annotation.Value` annotation
// used on constructor parameters. Use the fully qualified name inline.
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Vertex AI Gemini client with native function calling.
 *
 * <p>Flow per turn:
 * <ol>
 *   <li>Build conversation Content list from messages + system instruction</li>
 *   <li>Call {@code generateContent(...)} with the 28-tool catalog attached</li>
 *   <li>Inspect response — if it contains a {@code FunctionCall} part,
 *       execute the tool via {@link ToolExecutor}, append the
 *       {@code FunctionResponse} to the conversation, and loop back to (2)</li>
 *   <li>Otherwise return the final text</li>
 * </ol>
 *
 * <p>Authentication: Application Default Credentials. On Cloud Run that's
 * the runtime SA ({@code autosales-app}, with {@code roles/aiplatform.user}).
 */
@Component
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class VertexAiGeminiClient {

    private static final Logger log = LoggerFactory.getLogger(VertexAiGeminiClient.class);
    private static final int MAX_AGENT_ITERATIONS = 10;

    private final String projectId;
    private final String location;
    private final String modelName;
    private final boolean configured;
    private final ToolExecutor toolExecutor;

    public VertexAiGeminiClient(@Value("${gemini.project-id:}") String projectId,
                                @Value("${gemini.location:us-central1}") String location,
                                @Value("${gemini.model:gemini-2.5-flash}") String modelName,
                                ToolExecutor toolExecutor) {
        this.projectId = projectId;
        this.location = location;
        this.modelName = modelName;
        this.configured = projectId != null && !projectId.isBlank();
        this.toolExecutor = toolExecutor;
        if (!this.configured) {
            log.warn("Gemini client not configured — set gemini.project-id (or GEMINI_PROJECT_ID env)");
        } else {
            log.info("Gemini client configured: project={}, location={}, model={}",
                    projectId, location, modelName);
        }
    }

    public boolean isConfigured() {
        return configured;
    }

    public String getDisplayModel() {
        return "google/" + modelName;
    }

    /**
     * Run an agent turn — sends messages with tools, executes tool calls
     * iteratively, returns the final text reply.
     */
    public Reply complete(List<Map<String, Object>> messages, List<Tool> tools) {
        if (!configured) {
            throw new IllegalStateException("Gemini client is not configured");
        }

        StringBuilder systemInstruction = new StringBuilder();
        List<Content> conversation = new ArrayList<>();
        for (Map<String, Object> msg : messages) {
            String role = (String) msg.get("role");
            String content = msg.get("content") == null ? "" : msg.get("content").toString();
            if ("system".equals(role)) {
                if (systemInstruction.length() > 0) systemInstruction.append("\n\n");
                systemInstruction.append(content);
            } else {
                String geminiRole = "assistant".equals(role) ? "model" : "user";
                conversation.add(Content.newBuilder()
                        .setRole(geminiRole)
                        .addParts(Part.newBuilder().setText(content).build())
                        .build());
            }
        }

        try (VertexAI vertexAi = new VertexAI(projectId, location)) {
            GenerativeModel.Builder builder = new GenerativeModel.Builder()
                    .setModelName(modelName)
                    .setVertexAi(vertexAi);
            if (tools != null && !tools.isEmpty()) {
                builder.setTools(tools);
            }
            if (systemInstruction.length() > 0) {
                builder.setSystemInstruction(Content.newBuilder()
                        .addParts(Part.newBuilder().setText(systemInstruction.toString()).build())
                        .build());
            }
            GenerativeModel model = builder.build();

            int promptTokensTotal = 0;
            int completionTokensTotal = 0;
            List<ToolCallTrace> trace = new ArrayList<>();

            for (int iter = 0; iter < MAX_AGENT_ITERATIONS; iter++) {
                log.debug("Gemini iteration {} — conversation length={}", iter, conversation.size());
                GenerateContentResponse response = model.generateContent(conversation);

                if (response.getUsageMetadata() != null) {
                    promptTokensTotal += response.getUsageMetadata().getPromptTokenCount();
                    completionTokensTotal += response.getUsageMetadata().getCandidatesTokenCount();
                }

                if (response.getCandidatesCount() == 0) {
                    log.warn("Gemini returned no candidates — likely a safety block");
                    return new Reply("(Gemini returned no response — possibly blocked by safety filters.)",
                            promptTokensTotal, completionTokensTotal, trace);
                }

                Content responseContent = response.getCandidates(0).getContent();
                FunctionCall functionCall = null;
                StringBuilder textParts = new StringBuilder();
                for (Part part : responseContent.getPartsList()) {
                    if (part.hasFunctionCall()) {
                        functionCall = part.getFunctionCall();
                    } else if (!part.getText().isEmpty()) {
                        textParts.append(part.getText());
                    }
                }

                if (functionCall != null) {
                    String toolName = functionCall.getName();
                    Map<String, Object> args = structToMap(functionCall.getArgs());
                    log.info("Gemini tool call: {}({})", toolName, args);
                    String toolResult;
                    try {
                        toolResult = toolExecutor.execute(toolName, args);
                    } catch (Exception e) {
                        toolResult = "Error: " + e.getMessage();
                    }
                    trace.add(new ToolCallTrace(toolName, args, toolResult));

                    // Echo the model's call back into the conversation, then attach our response
                    conversation.add(responseContent);
                    conversation.add(Content.newBuilder()
                            .setRole("function")
                            .addParts(Part.newBuilder()
                                    .setFunctionResponse(FunctionResponse.newBuilder()
                                            .setName(toolName)
                                            .setResponse(Struct.newBuilder()
                                                    .putFields("result", com.google.protobuf.Value.newBuilder()
                                                            .setStringValue(toolResult).build())
                                                    .build())
                                            .build())
                                    .build())
                            .build());
                    continue;
                }

                // No function call — final text response
                String finalText = textParts.length() > 0 ? textParts.toString() : ResponseHandler.getText(response);
                log.info("Gemini turn complete: {} iterations, {} tool calls, prompt={} completion={}",
                        iter + 1, trace.size(), promptTokensTotal, completionTokensTotal);
                return new Reply(finalText, promptTokensTotal, completionTokensTotal, trace);
            }

            log.warn("Gemini agent loop hit max iterations ({})", MAX_AGENT_ITERATIONS);
            return new Reply(
                    "(I called several tools but couldn't reach a final answer within " + MAX_AGENT_ITERATIONS + " iterations.)",
                    promptTokensTotal, completionTokensTotal, trace);
        } catch (Exception e) {
            log.error("Gemini call failed", e);
            throw new GeminiException("Gemini error: " + e.getMessage(), e);
        }
    }

    /** Convert Protobuf Struct args to a Java map for ToolExecutor. */
    private Map<String, Object> structToMap(Struct struct) {
        Map<String, Object> out = new LinkedHashMap<>();
        if (struct == null) return out;
        for (Map.Entry<String, com.google.protobuf.Value> entry : struct.getFieldsMap().entrySet()) {
            com.google.protobuf.Value v = entry.getValue();
            switch (v.getKindCase()) {
                case STRING_VALUE -> out.put(entry.getKey(), v.getStringValue());
                case NUMBER_VALUE -> {
                    double d = v.getNumberValue();
                    if (d == Math.floor(d) && !Double.isInfinite(d)) {
                        out.put(entry.getKey(), (long) d);
                    } else {
                        out.put(entry.getKey(), d);
                    }
                }
                case BOOL_VALUE -> out.put(entry.getKey(), v.getBoolValue());
                case STRUCT_VALUE -> out.put(entry.getKey(), structToMap(v.getStructValue()));
                case NULL_VALUE -> out.put(entry.getKey(), null);
                default -> out.put(entry.getKey(), v.toString());
            }
        }
        return out;
    }

    public record Reply(String text, int promptTokens, int completionTokens, List<ToolCallTrace> toolCalls) {}

    public record ToolCallTrace(String toolName, Map<String, Object> args, String result) {}

    public static class GeminiException extends RuntimeException {
        public GeminiException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
