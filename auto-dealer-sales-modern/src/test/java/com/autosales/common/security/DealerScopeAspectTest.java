package com.autosales.common.security;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.reflect.MethodSignature;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DealerScopeAspectTest {

    @Mock private SystemUserRepository userRepository;
    @Mock private JoinPoint joinPoint;
    @Mock private MethodSignature signature;

    private DealerScopeAspect aspect;
    private DealerScoped annotation;

    @BeforeEach
    void setUp() {
        aspect = new DealerScopeAspect(userRepository);
        annotation = new DealerScoped() {
            @Override public Class<? extends java.lang.annotation.Annotation> annotationType() { return DealerScoped.class; }
            @Override public String param() { return "dealerCode"; }
        };
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateAs(String userId, String role) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userId, null,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role))));
    }

    private void wireJoinPoint(String paramName, Object paramValue) {
        when(joinPoint.getSignature()).thenReturn(signature);
        when(signature.getParameterNames()).thenReturn(new String[]{paramName});
        when(joinPoint.getArgs()).thenReturn(new Object[]{paramValue});
    }

    @Test
    void salesperson_cannotCrossDealers() {
        authenticateAs("SALES001", "SALESPERSON");
        when(userRepository.findByUserId("SALES001")).thenReturn(
                Optional.of(systemUser("SALES001", "S", "DLR01")));
        wireJoinPoint("dealerCode", "DLR05");

        AccessDeniedException ex = assertThrows(AccessDeniedException.class,
                () -> aspect.enforce(joinPoint, annotation));
        assertTrue(ex.getMessage().contains("DLR05"));
        assertTrue(ex.getMessage().contains("DLR01"));
    }

    @Test
    void salesperson_canAccessOwnDealer() {
        authenticateAs("SALES001", "SALESPERSON");
        when(userRepository.findByUserId("SALES001")).thenReturn(
                Optional.of(systemUser("SALES001", "S", "DLR01")));
        wireJoinPoint("dealerCode", "DLR01");

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void admin_canCrossAnyDealer() {
        authenticateAs("ADMIN001", "ADMIN");
        wireJoinPoint("dealerCode", "DLR99");

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void manager_canCrossAnyDealer() {
        authenticateAs("MGR001", "MANAGER");
        wireJoinPoint("dealerCode", "DLR99");

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void agentService_bypassesScopeCheck() {
        authenticateAs("AGENT_SERVICE", "AGENT_SERVICE");
        wireJoinPoint("dealerCode", "DLR99");

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void missingDealerParam_passesThrough() {
        authenticateAs("SALES001", "SALESPERSON");
        wireJoinPoint("dealerCode", null);

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void blankDealerParam_passesThrough() {
        authenticateAs("SALES001", "SALESPERSON");
        wireJoinPoint("dealerCode", "");

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void noSecurityContext_failsClosed() {
        SecurityContextHolder.clearContext();
        wireJoinPoint("dealerCode", "DLR01");

        assertThrows(AccessDeniedException.class,
                () -> aspect.enforce(joinPoint, annotation));
    }

    @Test
    void salesperson_caseInsensitiveDealerMatch() {
        authenticateAs("SALES001", "SALESPERSON");
        when(userRepository.findByUserId("SALES001")).thenReturn(
                Optional.of(systemUser("SALES001", "S", "DLR01")));
        wireJoinPoint("dealerCode", "dlr01");

        assertDoesNotThrow(() -> aspect.enforce(joinPoint, annotation));
    }

    private SystemUser systemUser(String userId, String userType, String dealerCode) {
        SystemUser u = new SystemUser();
        u.setUserId(userId);
        u.setUserType(userType);
        u.setDealerCode(dealerCode);
        return u;
    }
}
