package com.autosales.modules.discovery;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * Auto-generated tool descriptor for one Spring REST endpoint (B-discovery).
 *
 * <p>Walking {@code RequestMappingHandlerMapping} at startup yields one of
 * these per {@code @RestController} method. The agent's runtime retrieval
 * picks top-K matching descriptors per user turn and surfaces them
 * alongside the hand-curated tool catalog.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AutoToolDescriptor {

    /** Synthetic tool name — derived from path + verb (e.g. {@code get_api_admin_dealers}). */
    private String name;

    /** HTTP method — GET, POST, PUT, DELETE, PATCH. */
    private String httpMethod;

    /** URL path template, e.g. {@code /api/admin/dealers/{code}}. */
    private String path;

    /** Owning Spring controller's simple class name — useful for filtering / debugging. */
    private String controller;

    /** Underlying Java method name. */
    private String javaMethod;

    /** Human-readable description — auto-generated from path + verb when no Javadoc. */
    private String description;

    /** Path variables and request parameters. Best-effort extraction. */
    private List<Map<String, String>> parameters;

    /**
     * Safety level — drives whether this descriptor is exposed to the agent
     * at runtime. Levels (highest restriction first):
     * <ul>
     *   <li>AGENT_NO — never exposed (auth, agent's own endpoints, etc.)</li>
     *   <li>ADMIN_ONLY — admin-only writes (system config, user mgmt)</li>
     *   <li>WRITE_VIA_PROPOSE — write actions that have ActionHandler beans;
     *       only invokable through propose/confirm flow, not direct call</li>
     *   <li>WRITE — write actions without an ActionHandler (rare, demo cite)</li>
     *   <li>INTERNAL_READ — read endpoints not yet vetted for general agent use</li>
     *   <li>PUBLIC_READ — safe reads, freely exposed to the agent</li>
     * </ul>
     */
    private String safetyLevel;

    /** Free-form tags — e.g. ["read","admin"] — for filtering in the UI. */
    private List<String> tags;
}
