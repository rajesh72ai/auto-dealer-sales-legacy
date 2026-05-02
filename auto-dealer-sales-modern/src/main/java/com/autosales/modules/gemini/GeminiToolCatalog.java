package com.autosales.modules.gemini;

import com.autosales.modules.chat.ToolRegistry;
import com.google.cloud.vertexai.api.FunctionDeclaration;
import com.google.cloud.vertexai.api.Schema;
import com.google.cloud.vertexai.api.Tool;
import com.google.cloud.vertexai.api.Type;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Translates the 28-tool catalog from {@link ToolRegistry} (OpenAI
 * function-calling JSON shape) to Gemini's {@code FunctionDeclaration}
 * proto representation. Reuses ToolRegistry as the single source of truth
 * for tool names, descriptions, and parameter schemas — same definitions
 * already drive the chat module's free-tier providers.
 *
 * <p>Result: a single {@link Tool} containing all function declarations,
 * which is what Vertex AI expects ({@code List<Tool>} where each Tool can
 * carry many functions).
 */
@Component
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class GeminiToolCatalog {

    private final List<Tool> tools;

    public GeminiToolCatalog(ToolRegistry registry) {
        this.tools = List.of(buildTool(registry.getToolDefinitions()));
    }

    public List<Tool> getTools() {
        return tools;
    }

    @SuppressWarnings("unchecked")
    private Tool buildTool(List<Map<String, Object>> openAiDefinitions) {
        Tool.Builder toolBuilder = Tool.newBuilder();
        for (Map<String, Object> def : openAiDefinitions) {
            Map<String, Object> function = (Map<String, Object>) def.get("function");
            if (function == null) continue;

            String name = (String) function.get("name");
            String description = (String) function.get("description");
            Map<String, Object> parameters = (Map<String, Object>) function.get("parameters");

            FunctionDeclaration.Builder fnBuilder = FunctionDeclaration.newBuilder()
                    .setName(name)
                    .setDescription(description == null ? "" : description);

            if (parameters != null) {
                fnBuilder.setParameters(buildSchema(parameters));
            }
            toolBuilder.addFunctionDeclarations(fnBuilder.build());
        }
        return toolBuilder.build();
    }

    @SuppressWarnings("unchecked")
    private Schema buildSchema(Map<String, Object> jsonSchema) {
        Schema.Builder builder = Schema.newBuilder();
        String type = (String) jsonSchema.get("type");
        builder.setType(mapType(type));

        if ("object".equals(type)) {
            Map<String, Object> props = (Map<String, Object>) jsonSchema.get("properties");
            if (props != null) {
                for (Map.Entry<String, Object> entry : props.entrySet()) {
                    Map<String, Object> propSchema = (Map<String, Object>) entry.getValue();
                    builder.putProperties(entry.getKey(), buildSchema(propSchema));
                }
            }
            List<String> required = (List<String>) jsonSchema.get("required");
            if (required != null) {
                builder.addAllRequired(required);
            }
        }

        String description = (String) jsonSchema.get("description");
        if (description != null) {
            builder.setDescription(description);
        }
        return builder.build();
    }

    private Type mapType(String jsonType) {
        if (jsonType == null) return Type.TYPE_UNSPECIFIED;
        return switch (jsonType.toLowerCase()) {
            case "string" -> Type.STRING;
            case "integer" -> Type.INTEGER;
            case "number" -> Type.NUMBER;
            case "boolean" -> Type.BOOLEAN;
            case "array" -> Type.ARRAY;
            case "object" -> Type.OBJECT;
            default -> Type.TYPE_UNSPECIFIED;
        };
    }
}
