package com.autosales.common.util;

/**
 * Result of VIN check-digit validation.
 * Port of COMVALD0.cbl validation return area.
 */
public record VinValidationResult(
        boolean valid,
        String errorCode,
        String errorMessage
) {
    public static VinValidationResult success() {
        return new VinValidationResult(true, null, null);
    }

    public static VinValidationResult failure(String errorCode, String errorMessage) {
        return new VinValidationResult(false, errorCode, errorMessage);
    }
}
