package com.autosales.common.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a controller method whose {@code dealerCode} request parameter
 * must match the caller's own dealer — prevents a SALESPERSON at DLR01
 * from browsing DLR05 data via direct REST. Enforced by
 * {@link DealerScopeAspect}.
 *
 * <p>Bypassed for:
 * <ul>
 *   <li>ADMIN users — can see any dealer</li>
 *   <li>MANAGER users — can see any dealer (for multi-lot oversight)</li>
 *   <li>AGENT_SERVICE principal — the agent-service caller has no dealer
 *       context; scope enforcement for agent-mediated requests happens in
 *       the skill + {@code AgentService.prependUserContext}, not here</li>
 * </ul>
 *
 * <p>Default param name is {@code dealerCode}; override via {@link #param()}
 * for endpoints that use a different name (e.g., {@code dealer}).
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface DealerScoped {
    String param() default "dealerCode";
}
