package com.autosales.common.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Authenticates requests using a static API key via the X-API-Key header.
 * Used by OpenClaw AI gateway and other service-to-service callers.
 *
 * Grants {@code ROLE_AGENT_SERVICE} — NOT {@code ROLE_OPERATOR}. This matters
 * because human dealership operators authenticate via JWT and receive
 * {@code ROLE_OPERATOR}; conflating the two would let OpenClaw reach
 * write endpoints meant for human operators (e.g., deal approval, mark
 * shipment arrived) and bypass the Phase 3 propose→confirm→commit flow.
 *
 * Endpoints must opt in to service access by including
 * {@code 'AGENT_SERVICE'} in their {@code @PreAuthorize} role list. Phase-3
 * wrapped write endpoints (create deal, approve deal, add trade-in,
 * apply incentive, submit finance app, close warranty claim, transfer
 * stock, mark shipment arrived) deliberately omit AGENT_SERVICE — the
 * only legitimate agent path for those is the in-process marker flow
 * orchestrated by {@code ActionService}.
 */
@Component
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(ApiKeyAuthenticationFilter.class);
    private static final String API_KEY_HEADER = "X-API-Key";
    private static final String SERVICE_PRINCIPAL = "AGENT_SERVICE";
    private static final String SERVICE_ROLE = "ROLE_AGENT_SERVICE";

    @Value("${api.key}")
    private String apiKey;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        // Only process if no authentication is already set (let JWT take precedence if present)
        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            String requestApiKey = request.getHeader(API_KEY_HEADER);

            if (StringUtils.hasText(requestApiKey) && requestApiKey.equals(apiKey)) {
                List<SimpleGrantedAuthority> authorities = List.of(
                        new SimpleGrantedAuthority(SERVICE_ROLE)
                );

                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(SERVICE_PRINCIPAL, null, authorities);
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authentication);
                log.debug("API key authenticated for {}", SERVICE_PRINCIPAL);
            }
        }

        filterChain.doFilter(request, response);
    }
}
