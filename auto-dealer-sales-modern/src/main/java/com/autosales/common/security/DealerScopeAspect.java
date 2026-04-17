package com.autosales.common.security;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Enforces {@link DealerScoped} — rejects cross-dealer reads for non-admin,
 * non-manager, non-service callers.
 *
 * <p>Addresses AI Agent safety audit gap #5 (cross-dealer read guard) —
 * a SALESPERSON at DLR01 calling {@code GET /api/customers?dealerCode=DLR05}
 * via direct JWT now returns 403 instead of DLR05's customer list.
 *
 * <p>Deliberately does NOT enforce on AGENT_SERVICE principal: the agent
 * tool-executor calls back to the API with a service key and has no end-user
 * dealer context. Cross-dealer restraint for agent-mediated requests is
 * handled in the skill's prepended user context, not here.
 */
@Aspect
@Component
public class DealerScopeAspect {

    private static final Logger log = LoggerFactory.getLogger(DealerScopeAspect.class);
    private static final String AGENT_SERVICE_PRINCIPAL = "AGENT_SERVICE";

    private final SystemUserRepository userRepository;

    public DealerScopeAspect(SystemUserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Before("@annotation(scoped)")
    public void enforce(JoinPoint jp, DealerScoped scoped) {
        String requestedDealer = extractDealerCode(jp, scoped.param());
        if (requestedDealer == null || requestedDealer.isBlank()) {
            return;
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) {
            // Unauthenticated requests are blocked by @PreAuthorize upstream;
            // if we somehow got here with no context, fail closed.
            throw new AccessDeniedException("No authentication context");
        }

        String principal = auth.getName();
        if (AGENT_SERVICE_PRINCIPAL.equals(principal)) {
            return;
        }

        if (hasAuthority(auth, "ROLE_ADMIN") || hasAuthority(auth, "ROLE_MANAGER")) {
            return;
        }

        SystemUser user = userRepository.findByUserId(principal).orElse(null);
        String ownDealer = user != null ? user.getDealerCode() : null;
        if (ownDealer == null || !ownDealer.equalsIgnoreCase(requestedDealer)) {
            log.warn("Cross-dealer access denied: user={} ownDealer={} requested={}",
                    principal, ownDealer, requestedDealer);
            throw new AccessDeniedException(
                    "Access denied: your dealer scope ("
                            + (ownDealer != null ? ownDealer : "none")
                            + ") does not permit access to dealer " + requestedDealer);
        }
    }

    private String extractDealerCode(JoinPoint jp, String paramName) {
        MethodSignature sig = (MethodSignature) jp.getSignature();
        String[] paramNames = sig.getParameterNames();
        if (paramNames == null) return null;
        Object[] args = jp.getArgs();
        for (int i = 0; i < paramNames.length; i++) {
            if (paramName.equals(paramNames[i]) && args[i] != null) {
                return args[i].toString();
            }
        }
        return null;
    }

    private boolean hasAuthority(Authentication auth, String role) {
        for (GrantedAuthority ga : auth.getAuthorities()) {
            if (role.equals(ga.getAuthority())) return true;
        }
        return false;
    }
}
