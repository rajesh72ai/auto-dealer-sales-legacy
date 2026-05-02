package com.autosales.modules.gemini;

import com.google.cloud.vertexai.VertexAI;
import com.google.cloud.vertexai.api.Content;
import com.google.cloud.vertexai.api.GenerateContentResponse;
import com.google.cloud.vertexai.api.Part;
import com.google.cloud.vertexai.generativeai.GenerativeModel;
import com.google.cloud.vertexai.generativeai.ResponseHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Thin wrapper around the Vertex AI SDK for Gemini.
 *
 * <p>Authenticates via Application Default Credentials — on Cloud Run,
 * that's the runtime service account ({@code autosales-app}), which we've
 * granted {@code roles/aiplatform.user}. Locally, ADC comes from
 * {@code gcloud auth application-default login}, but local Compose runs
 * the OpenClaw provider so this client isn't instantiated.
 *
 * <p>B1.1 scope: plain text completion. No tools, no streaming, no
 * function calling. Those land in B1.2.
 */
@Component
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class VertexAiGeminiClient {

    private static final Logger log = LoggerFactory.getLogger(VertexAiGeminiClient.class);

    private final String projectId;
    private final String location;
    private final String modelName;
    private final boolean configured;

    public VertexAiGeminiClient(@Value("${gemini.project-id:}") String projectId,
                                @Value("${gemini.location:us-central1}") String location,
                                @Value("${gemini.model:gemini-2.5-flash}") String modelName) {
        this.projectId = projectId;
        this.location = location;
        this.modelName = modelName;
        this.configured = projectId != null && !projectId.isBlank();
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

    /** Display model id, e.g. {@code google/gemini-2.5-flash}. */
    public String getDisplayModel() {
        return "google/" + modelName;
    }

    /**
     * Send a list of messages to Gemini and get back a text reply.
     *
     * <p>Each message is a map with keys {@code role} ("user" / "assistant" /
     * "system") and {@code content} (the text). System messages are merged
     * into a {@code systemInstruction}; user / assistant messages become
     * {@code Content} parts in alternating turns.
     */
    public Reply complete(List<Map<String, Object>> messages) {
        if (!configured) {
            throw new IllegalStateException("Gemini client is not configured");
        }

        // Split out system messages — Gemini accepts a single systemInstruction
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
                Content c = Content.newBuilder()
                        .setRole(geminiRole)
                        .addParts(Part.newBuilder().setText(content).build())
                        .build();
                conversation.add(c);
            }
        }

        try (VertexAI vertexAi = new VertexAI(projectId, location)) {
            GenerativeModel.Builder builder = new GenerativeModel.Builder()
                    .setModelName(modelName)
                    .setVertexAi(vertexAi);
            if (systemInstruction.length() > 0) {
                Content sys = Content.newBuilder()
                        .addParts(Part.newBuilder().setText(systemInstruction.toString()).build())
                        .build();
                builder.setSystemInstruction(sys);
            }
            GenerativeModel model = builder.build();

            log.debug("Calling Gemini: model={} messages={} hasSystem={}",
                    modelName, conversation.size(), systemInstruction.length() > 0);
            GenerateContentResponse response = model.generateContent(conversation);
            String text = ResponseHandler.getText(response);

            int promptTokens = response.getUsageMetadata().getPromptTokenCount();
            int completionTokens = response.getUsageMetadata().getCandidatesTokenCount();
            return new Reply(text == null ? "" : text, promptTokens, completionTokens);
        } catch (Exception e) {
            log.error("Gemini call failed", e);
            throw new GeminiException("Gemini error: " + e.getMessage(), e);
        }
    }

    public record Reply(String text, int promptTokens, int completionTokens) {}

    public static class GeminiException extends RuntimeException {
        public GeminiException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
