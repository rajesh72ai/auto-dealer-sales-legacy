package com.autosales.common.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.Field;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link ApiKeyAuthenticationFilter} — static API key auth for OpenClaw.
 */
@ExtendWith(MockitoExtension.class)
class ApiKeyAuthenticationFilterTest {

    private ApiKeyAuthenticationFilter filter;

    @Mock
    private HttpServletRequest request;
    @Mock
    private HttpServletResponse response;
    @Mock
    private FilterChain filterChain;

    private static final String TEST_API_KEY = "test-api-key-12345";

    @BeforeEach
    void setUp() throws Exception {
        SecurityContextHolder.clearContext();
        filter = new ApiKeyAuthenticationFilter();
        // Inject the api key via reflection since @Value won't work in unit test
        Field apiKeyField = ApiKeyAuthenticationFilter.class.getDeclaredField("apiKey");
        apiKeyField.setAccessible(true);
        apiKeyField.set(filter, TEST_API_KEY);
    }

    @Test
    @DisplayName("Valid API key authenticates as AGENT_SERVICE (not OPERATOR)")
    void testValidApiKey() throws Exception {
        when(request.getHeader("X-API-Key")).thenReturn(TEST_API_KEY);

        filter.doFilterInternal(request, response, filterChain);

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertNotNull(auth, "Authentication should be set");
        assertEquals("AGENT_SERVICE", auth.getPrincipal());
        assertTrue(auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_AGENT_SERVICE")),
                "API-key auth should grant ROLE_AGENT_SERVICE");
        assertFalse(auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_OPERATOR")),
                "API-key auth must NOT grant ROLE_OPERATOR — that's reserved for human dealership operator users via JWT");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("Invalid API key should NOT authenticate")
    void testInvalidApiKey() throws Exception {
        when(request.getHeader("X-API-Key")).thenReturn("wrong-key");

        filter.doFilterInternal(request, response, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication(),
                "Authentication should NOT be set for invalid key");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("Missing API key header should NOT authenticate")
    void testMissingApiKey() throws Exception {
        when(request.getHeader("X-API-Key")).thenReturn(null);

        filter.doFilterInternal(request, response, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication(),
                "Authentication should NOT be set when header is missing");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("Empty API key header should NOT authenticate")
    void testEmptyApiKey() throws Exception {
        when(request.getHeader("X-API-Key")).thenReturn("");

        filter.doFilterInternal(request, response, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication(),
                "Authentication should NOT be set for empty key");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    @DisplayName("API key filter should not override existing JWT authentication")
    void testDoesNotOverrideExistingAuth() throws Exception {
        // Simulate JWT already authenticated
        var existingAuth = new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                "ADMIN001", null, java.util.List.of(
                        new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ADMIN")));
        SecurityContextHolder.getContext().setAuthentication(existingAuth);

        // Note: no stubbing for getHeader — filter should skip API key check entirely
        // when authentication is already set (JWT took precedence)

        filter.doFilterInternal(request, response, filterChain);

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertEquals("ADMIN001", auth.getPrincipal(), "Should keep existing JWT auth, not override with API key");
        verify(filterChain).doFilter(request, response);
    }
}
