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
    /**
     * Per-iteration soft cap on Vertex AI generateContent latency. Cloud Run's
     * outer request timeout is 300s; if a single Gemini round-trip eats more
     * than this, we bail out gracefully with a partial reply rather than let
     * the whole agent loop time out and Cloud Run truncate the response. 60s
     * is generous — typical Flash latency is 3-6s.
     */
    private static final long PER_TURN_TIMEOUT_SECONDS = 60;

    /**
     * Shared executor for the timeout wrapper around generateContent. Cached
     * thread pool — daemon threads, capped by JVM resources rather than a
     * fixed size, since each agent turn issues one short-lived task per
     * iteration and they don't stack.
     */
    private static final java.util.concurrent.ExecutorService TIMEOUT_EXECUTOR =
            java.util.concurrent.Executors.newCachedThreadPool(r -> {
                Thread t = new Thread(r, "gemini-timeout-worker");
                t.setDaemon(true);
                return t;
            });

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
        return complete(messages, tools, null);
    }

    /**
     * Run an agent turn with an optional per-call recorder. The recorder is
     * invoked synchronously after each tool execution with the call's name,
     * arguments, result, elapsed time, and error flag — giving the caller
     * a hook to persist a per-tool-call audit row (see B2).
     */
    public Reply complete(List<Map<String, Object>> messages, List<Tool> tools, ToolCallRecorder recorder) {
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

                // Per-turn timeout — if a single generateContent eats more than
                // PER_TURN_TIMEOUT_SECONDS (60s by default), bail out gracefully
                // with a partial reply instead of letting Cloud Run's outer 300s
                // request timeout truncate the SSE response.
                final List<Content> conv = conversation;
                final GenerativeModel m = model;
                GenerateContentResponse response;
                try {
                    response = java.util.concurrent.CompletableFuture
                            .supplyAsync(() -> {
                                try {
                                    return m.generateContent(conv);
                                } catch (java.io.IOException ioe) {
                                    throw new java.util.concurrent.CompletionException(ioe);
                                }
                            }, TIMEOUT_EXECUTOR)
                            .get(PER_TURN_TIMEOUT_SECONDS, java.util.concurrent.TimeUnit.SECONDS);
                } catch (java.util.concurrent.TimeoutException te) {
                    log.warn("Gemini generateContent timed out after {}s on iteration {} (trace={} tool calls so far)",
                            PER_TURN_TIMEOUT_SECONDS, iter, trace.size());
                    String partial = "(The agent took longer than " + PER_TURN_TIMEOUT_SECONDS
                            + "s on iteration " + (iter + 1) + ". "
                            + (trace.isEmpty()
                                    ? "No tool calls completed."
                                    : "Partial result from " + trace.size() + " tool call(s) collected.")
                            + " Try a more focused prompt or break the request into smaller turns.)";
                    return new Reply(partial, promptTokensTotal, completionTokensTotal, trace);
                } catch (java.util.concurrent.ExecutionException ee) {
                    Throwable cause = ee.getCause() != null ? ee.getCause() : ee;
                    throw new GeminiException("Gemini error: " + cause.getMessage(), cause);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new GeminiException("Gemini call interrupted", ie);
                }

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
                // Gemini may emit MULTIPLE function_call parts in one response when it
                // wants to fan out parallel calls (e.g., "do this for all 12 dealers" →
                // 12 parallel get_floorplan_exposure calls). The Vertex AI SDK requires
                // us to send back exactly one function_response part per function_call
                // part, in a single function-role Content message. Earlier B1.2/B2 code
                // captured only the LAST function_call, sent back 1 response, and Gemini
                // refused on the next iteration with INVALID_ARGUMENT. Captured as
                // gotcha #14 in feedback_gcp_gotchas.md.
                List<FunctionCall> functionCalls = new ArrayList<>();
                StringBuilder textParts = new StringBuilder();
                for (Part part : responseContent.getPartsList()) {
                    if (part.hasFunctionCall()) {
                        functionCalls.add(part.getFunctionCall());
                    } else if (!part.getText().isEmpty()) {
                        textParts.append(part.getText());
                    }
                }

                if (!functionCalls.isEmpty()) {
                    // Echo the model's request (containing N function_call parts) back into the conversation
                    conversation.add(responseContent);

                    // Build a single function-role Content with N function_response parts —
                    // one for each function_call, in the same order. Execute each call,
                    // capture per-call elapsed time, and persist via the recorder.
                    Content.Builder responseBuilder = Content.newBuilder().setRole("function");
                    for (FunctionCall fc : functionCalls) {
                        String toolName = fc.getName();
                        Map<String, Object> args = structToMap(fc.getArgs());
                        log.info("Gemini tool call: {}({})", toolName, args);
                        long started = System.currentTimeMillis();
                        String toolResult;
                        boolean errored = false;
                        try {
                            toolResult = toolExecutor.execute(toolName, args);
                        } catch (Exception e) {
                            toolResult = "Error: " + e.getMessage();
                            errored = true;
                        }
                        long elapsedMs = System.currentTimeMillis() - started;
                        trace.add(new ToolCallTrace(toolName, args, toolResult, elapsedMs, errored));
                        if (recorder != null) {
                            try {
                                recorder.record(toolName, args, toolResult, elapsedMs, errored);
                            } catch (Exception recErr) {
                                // Don't let an audit failure break the agent loop
                                log.warn("ToolCallRecorder threw: {}", recErr.getMessage());
                            }
                        }
                        responseBuilder.addParts(Part.newBuilder()
                                .setFunctionResponse(FunctionResponse.newBuilder()
                                        .setName(toolName)
                                        .setResponse(Struct.newBuilder()
                                                .putFields("result", com.google.protobuf.Value.newBuilder()
                                                        .setStringValue(toolResult).build())
                                                .build())
                                        .build())
                                .build());
                    }
                    conversation.add(responseBuilder.build());
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

    public record ToolCallTrace(String toolName, Map<String, Object> args, String result,
                                long elapsedMs, boolean errored) {
        /** Backwards-compatible constructor (older callers in tests). */
        public ToolCallTrace(String toolName, Map<String, Object> args, String result) {
            this(toolName, args, result, 0L, false);
        }
    }

    /**
     * Callback invoked once per tool execution inside the agent loop. Use it
     * to persist an audit row (e.g., {@code AgentToolCallAuditService.recordReadToolCall})
     * without coupling the client to the audit subsystem.
     */
    @FunctionalInterface
    public interface ToolCallRecorder {
        void record(String toolName, Map<String, Object> args, String result, long elapsedMs, boolean errored);
    }

    public static class GeminiException extends RuntimeException {
        public GeminiException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
