package com.autosales.modules.gemini;

import com.autosales.modules.agent.action.ActionRegistry;
import com.autosales.modules.chat.ToolRegistry;
import com.google.cloud.vertexai.api.FunctionDeclaration;
import com.google.cloud.vertexai.api.Schema;
import com.google.cloud.vertexai.api.Tool;
import com.google.cloud.vertexai.api.Type;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Translates the read-only subset of {@link ToolRegistry} (OpenAI
 * function-calling JSON shape) to Gemini's {@code FunctionDeclaration}
 * proto representation. Reuses ToolRegistry as the single source of truth
 * for tool names, descriptions, and parameter schemas.
 *
 * <p><b>Read/write split:</b> Any tool name that has a registered
 * {@link com.autosales.modules.agent.action.ActionHandler} (i.e., a write
 * action behind the Phase 3 propose/confirm framework) is excluded from
 * the function-calling catalog. This forces Gemini to use the
 * {@code [[PROPOSE]]} marker pattern for writes instead of executing them
 * directly via function calling — keeping the safety framework intact.
 * The marker convention is taught to Gemini in
 * {@code GeminiAgentService.SYSTEM_INSTRUCTION}.
 *
 * <p>Result: a single {@link Tool} containing all read-only function
 * declarations, which is what Vertex AI expects ({@code List<Tool>}
 * where each Tool can carry many functions).
 */
@Component
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class GeminiToolCatalog {

    private static final Logger log = LoggerFactory.getLogger(GeminiToolCatalog.class);

    private final List<Tool> tools;
    private final List<String> readToolNames;
    private final Set<String> writeToolNames;

    public GeminiToolCatalog(ToolRegistry registry, ActionRegistry actionRegistry) {
        this.writeToolNames = Set.copyOf(actionRegistry.names());
        this.readToolNames = new ArrayList<>();
        Tool tool = buildTool(registry.getToolDefinitions(), this.writeToolNames, this.readToolNames);
        this.tools = List.of(tool);
        log.info("Gemini tool catalog: exposing {} read tools to function calling; {} write tools reserved for [[PROPOSE]] marker",
                readToolNames.size(), writeToolNames.size());
    }

    public List<Tool> getTools() {
        return tools;
    }

    /** Read-only tool names exposed to Gemini for native function calling. */
    public List<String> getReadToolNames() {
        return List.copyOf(readToolNames);
    }

    /** Write tool names reserved for the {@code [[PROPOSE]]} marker flow. */
    public Set<String> getWriteToolNames() {
        return writeToolNames;
    }

    @SuppressWarnings("unchecked")
    private Tool buildTool(List<Map<String, Object>> openAiDefinitions,
                           Set<String> writes,
                           List<String> readNamesOut) {
        Tool.Builder toolBuilder = Tool.newBuilder();
        for (Map<String, Object> def : openAiDefinitions) {
            Map<String, Object> function = (Map<String, Object>) def.get("function");
            if (function == null) continue;

            String name = (String) function.get("name");
            if (name == null) continue;
            if (writes.contains(name)) {
                // Write tool — exclude from function-calling catalog;
                // Gemini must use [[PROPOSE]] marker instead.
                continue;
            }
            String description = (String) function.get("description");
            Map<String, Object> parameters = (Map<String, Object>) function.get("parameters");

            FunctionDeclaration.Builder fnBuilder = FunctionDeclaration.newBuilder()
                    .setName(name)
                    .setDescription(description == null ? "" : description);

            if (parameters != null) {
                fnBuilder.setParameters(buildSchema(parameters));
            }
            toolBuilder.addFunctionDeclarations(fnBuilder.build());
            readNamesOut.add(name);
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
