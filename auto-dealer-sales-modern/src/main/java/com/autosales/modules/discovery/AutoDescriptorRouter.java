package com.autosales.modules.discovery;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Routes auto-discovered tool calls to real Spring REST endpoints.
 *
 * <p>When the agent emits a {@code function_call} for a synthetic tool
 * name (e.g. {@code get_api_admin_lot-locations}), {@link com.autosales.modules.chat.ToolExecutor}
 * consults this router as a fallback after its hand-curated switch. The
 * router looks up the descriptor in a name → descriptor index built from
 * {@link ToolDescriptorExtractor#getCatalog()} at startup, builds the URL
 * from the descriptor's path template + the supplied args, and forwards
 * the call to the local Spring app over an X-API-Key-authenticated
 * {@link RestClient} (same pattern as ToolExecutor's curated route).
 *
 * <p><b>Safety enforcement.</b> Even though
 * {@link KeywordRetrievalService} is the primary safety filter (only
 * exposing {@code PUBLIC_READ} / {@code INTERNAL_READ} GETs to Gemini),
 * this router re-checks the descriptor's classification on every
 * invocation. A model that hallucinates a write-flavored synthetic name
 * cannot trip the framework — the router refuses the call and returns
 * an explanatory error string the agent can surface to the user.
 */
@Component
public class AutoDescriptorRouter {

    private static final Logger log = LoggerFactory.getLogger(AutoDescriptorRouter.class);

    /** Allowed safety levels — must match {@link KeywordRetrievalService#ALLOWED_SAFETY}. */
    private static final Set<String> ALLOWED_SAFETY = Set.of("PUBLIC_READ", "INTERNAL_READ");

    private final ToolDescriptorExtractor extractor;
    private final RestClient restClient;

    private Map<String, AutoToolDescriptor> nameIndex = Map.of();

    public AutoDescriptorRouter(ToolDescriptorExtractor extractor,
                                @Value("${api.key}") String apiKey,
                                @Value("${server.port:8480}") int port) {
        this.extractor = extractor;
        this.restClient = RestClient.builder()
                .baseUrl("http://localhost:" + port)
                .defaultHeader("X-API-Key", apiKey)
                .build();
    }

    @PostConstruct
    void index() {
        Map<String, AutoToolDescriptor> map = new HashMap<>();
        for (AutoToolDescriptor d : extractor.getCatalog()) {
            map.put(d.getName(), d);
        }
        this.nameIndex = Map.copyOf(map);
        log.info("AutoDescriptorRouter: indexed {} synthetic tool names from extracted catalog",
                this.nameIndex.size());
    }

    /**
     * Attempt to route a tool call against the auto-discovered catalog.
     * Returns {@link Optional#empty()} when {@code toolName} is not in the
     * synthetic index — the caller should treat that as "unknown tool".
     * Returns {@link Optional#of} with the response body (or an error
     * message) when the name was recognized.
     */
    public Optional<String> route(String toolName, Map<String, Object> args) {
        AutoToolDescriptor d = nameIndex.get(toolName);
        if (d == null) return Optional.empty();

        if (d.getSafetyLevel() == null || !ALLOWED_SAFETY.contains(d.getSafetyLevel())) {
            log.warn("AutoDescriptorRouter refused {}: safetyLevel={}", toolName, d.getSafetyLevel());
            return Optional.of("Refused: tool '" + toolName + "' has safetyLevel="
                    + d.getSafetyLevel() + " and is not callable via auto-discovery."
                    + " Writes go through the [[PROPOSE]] flow instead.");
        }
        if (!"GET".equalsIgnoreCase(d.getHttpMethod())) {
            log.warn("AutoDescriptorRouter refused {}: method={} (only GET allowed)",
                    toolName, d.getHttpMethod());
            return Optional.of("Refused: only GET methods are exposed via auto-discovery."
                    + " Tool '" + toolName + "' uses " + d.getHttpMethod() + ".");
        }

        try {
            String url = buildUrl(d, args);
            log.info("AutoDescriptorRouter GET {} (tool={})", url, toolName);
            String body = restClient.get().uri(url).retrieve().body(String.class);
            return Optional.of(body == null ? "" : body);
        } catch (IllegalArgumentException iae) {
            return Optional.of("Error: " + iae.getMessage());
        } catch (Exception e) {
            log.warn("AutoDescriptorRouter call failed for {}: {}", toolName, e.getMessage());
            return Optional.of("Error calling " + d.getPath() + ": " + e.getMessage());
        }
    }

    /**
     * Compose the full request URL from a descriptor + supplied args.
     * Path placeholders ({@code {name}}) are replaced with arg values
     * (URL-encoded). Declared query params are appended when present.
     * Any remaining args are appended as pass-through query params —
     * helpful when the LLM provides values like {@code dealerCode} that
     * the descriptor didn't surface (e.g. Spring's {@code Pageable} maps
     * {@code page}/{@code size} from query without explicit annotations).
     */
    private String buildUrl(AutoToolDescriptor d, Map<String, Object> args) {
        String url = d.getPath();
        Set<String> consumedKeys = new HashSet<>();

        if (d.getParameters() != null) {
            for (Map<String, String> p : d.getParameters()) {
                String name = p.get("name");
                if (name == null) continue;
                if ("path".equals(p.get("kind"))) {
                    Object val = args == null ? null : args.get(name);
                    if (val == null) {
                        throw new IllegalArgumentException(
                                "Missing required path parameter '" + name + "' for " + d.getPath());
                    }
                    url = url.replace("{" + name + "}", encode(val.toString()));
                    consumedKeys.add(name);
                }
            }
        }

        StringBuilder qs = new StringBuilder();
        if (d.getParameters() != null) {
            for (Map<String, String> p : d.getParameters()) {
                String name = p.get("name");
                if (name == null) continue;
                if ("query".equals(p.get("kind"))) {
                    Object val = args == null ? null : args.get(name);
                    if (val == null || val.toString().isBlank()) continue;
                    appendQs(qs, name, val.toString());
                    consumedKeys.add(name);
                }
            }
        }

        if (args != null) {
            for (Map.Entry<String, Object> e : args.entrySet()) {
                if (consumedKeys.contains(e.getKey())) continue;
                if (e.getValue() == null || e.getValue().toString().isBlank()) continue;
                appendQs(qs, e.getKey(), e.getValue().toString());
            }
        }

        return url + qs;
    }

    private static void appendQs(StringBuilder qs, String name, String value) {
        qs.append(qs.length() == 0 ? "?" : "&");
        qs.append(encode(name)).append("=").append(encode(value));
    }

    private static String encode(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    /** Test/debug accessor — returns the synthetic name index size. */
    public int indexSize() {
        return nameIndex.size();
    }
}
