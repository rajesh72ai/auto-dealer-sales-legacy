package com.autosales.common.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link UserRole} — validates role enum including OPERATOR for OpenClaw AI.
 */
class UserRoleTest {

    @Test
    @DisplayName("All 6 roles should exist with correct codes")
    void testAllRolesExist() {
        assertEquals(6, UserRole.values().length);
        assertEquals("A", UserRole.ADMIN.getCode());
        assertEquals("M", UserRole.MANAGER.getCode());
        assertEquals("S", UserRole.SALESPERSON.getCode());
        assertEquals("F", UserRole.FINANCE.getCode());
        assertEquals("C", UserRole.CLERK.getCode());
        assertEquals("O", UserRole.OPERATOR.getCode());
    }

    @Test
    @DisplayName("fromCode('O') should return OPERATOR role")
    void testOperatorFromCode() {
        UserRole role = UserRole.fromCode("O");
        assertEquals(UserRole.OPERATOR, role);
        assertEquals("O", role.getCode());
    }

    @Test
    @DisplayName("fromCode should resolve all valid codes")
    void testFromCodeAllValid() {
        assertEquals(UserRole.ADMIN, UserRole.fromCode("A"));
        assertEquals(UserRole.MANAGER, UserRole.fromCode("M"));
        assertEquals(UserRole.SALESPERSON, UserRole.fromCode("S"));
        assertEquals(UserRole.FINANCE, UserRole.fromCode("F"));
        assertEquals(UserRole.CLERK, UserRole.fromCode("C"));
        assertEquals(UserRole.OPERATOR, UserRole.fromCode("O"));
    }

    @Test
    @DisplayName("fromCode with invalid code should throw IllegalArgumentException")
    void testFromCodeInvalid() {
        assertThrows(IllegalArgumentException.class, () -> UserRole.fromCode("X"));
        assertThrows(IllegalArgumentException.class, () -> UserRole.fromCode(""));
        assertThrows(IllegalArgumentException.class, () -> UserRole.fromCode("ADMIN"));
    }

    @Test
    @DisplayName("OPERATOR role name should be 'OPERATOR' for Spring Security ROLE_ prefix")
    void testOperatorRoleName() {
        assertEquals("OPERATOR", UserRole.OPERATOR.name());
        // This is what gets set as ROLE_OPERATOR in JwtAuthenticationFilter
        String authority = "ROLE_" + UserRole.OPERATOR.name();
        assertEquals("ROLE_OPERATOR", authority);
    }

    @Test
    @DisplayName("OPERATOR code 'O' should be unique and not conflict with other roles")
    void testOperatorCodeUnique() {
        long countO = 0;
        for (UserRole role : UserRole.values()) {
            if ("O".equals(role.getCode())) countO++;
        }
        assertEquals(1, countO, "Code 'O' should map to exactly one role");
    }
}
