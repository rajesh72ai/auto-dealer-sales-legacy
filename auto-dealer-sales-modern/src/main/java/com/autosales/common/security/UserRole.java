package com.autosales.common.security;

public enum UserRole {
    ADMIN("A"),
    MANAGER("M"),
    SALESPERSON("S"),
    FINANCE("F"),
    CLERK("C");

    private final String code;

    UserRole(String code) { this.code = code; }

    public String getCode() { return code; }

    public static UserRole fromCode(String code) {
        for (UserRole role : values()) {
            if (role.code.equals(code)) return role;
        }
        throw new IllegalArgumentException("Unknown user type code: " + code);
    }
}
