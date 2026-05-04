package com.autosales.modules.gemini;

import com.autosales.modules.discovery.AutoToolDescriptor;
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
 * Translates auto-extracted {@link AutoToolDescriptor} entries (B-discovery)
 * into Vertex AI {@link FunctionDeclaration} proto representations,
 * mirroring the conversion {@link GeminiToolCatalog} does for the curated
 * 32-tool catalog.
 *
 * <p>Each path/query parameter on the descriptor becomes a String property
 * in the synthesized JSON Schema. Path variables are marked required;
 * query parameters are not (Spring controllers default them).
 *
 * <p>Body parameters are rare in the read-only subset we expose here
 * (PUBLIC_READ + INTERNAL_READ) and are intentionally NOT translated —
 * those endpoints would be unusable through this synthetic surface
 * anyway. {@link com.autosales.modules.discovery.KeywordRetrievalService}
 * filters to GET-only so we never see one in practice.
 */
@Component
@ConditionalOnProperty(name = "agent.provider", havingValue = "gemini")
public class AutoToolGeminiBuilder {

    /**
     * Build a single {@link Tool} carrying one {@link FunctionDeclaration}
     * per supplied descriptor. Returns {@code null} when the input list is
     * empty so callers can skip adding it to the per-turn tools list.
     */
    public Tool buildToolFromDescriptors(List<AutoToolDescriptor> descriptors) {
        if (descriptors == null || descriptors.isEmpty()) return null;

        Tool.Builder toolBuilder = Tool.newBuilder();
        for (AutoToolDescriptor d : descriptors) {
            FunctionDeclaration fn = toFunctionDeclaration(d);
            if (fn != null) toolBuilder.addFunctionDeclarations(fn);
        }
        return toolBuilder.build();
    }

    /** Convert a single descriptor to a {@link FunctionDeclaration}. */
    public FunctionDeclaration toFunctionDeclaration(AutoToolDescriptor d) {
        if (d == null || d.getName() == null) return null;

        FunctionDeclaration.Builder fn = FunctionDeclaration.newBuilder()
                .setName(d.getName())
                .setDescription(d.getDescription() == null
                        ? "Auto-discovered " + d.getHttpMethod() + " " + d.getPath()
                        : d.getDescription());

        Schema.Builder params = Schema.newBuilder().setType(Type.OBJECT);
        List<String> required = new ArrayList<>();
        if (d.getParameters() != null) {
            for (Map<String, String> param : d.getParameters()) {
                String name = param.get("name");
                String kind = param.get("kind");
                if (name == null || name.isBlank()) continue;
                // Body params are excluded — see class javadoc.
                if (!"path".equals(kind) && !"query".equals(kind)) continue;

                String paramDesc = ("path".equals(kind))
                        ? "Path variable for " + d.getPath()
                        : "Query parameter (" + name + ")";
                Schema p = Schema.newBuilder()
                        .setType(Type.STRING)
                        .setDescription(paramDesc)
                        .build();
                params.putProperties(name, p);

                // Path variables are always required (URL placeholder won't
                // resolve without them). Query params are required only when
                // the @RequestParam metadata explicitly says so.
                if ("path".equals(kind) || "true".equalsIgnoreCase(param.get("required"))) {
                    required.add(name);
                }
            }
        }
        params.addAllRequired(required);
        fn.setParameters(params.build());
        return fn.build();
    }
}
