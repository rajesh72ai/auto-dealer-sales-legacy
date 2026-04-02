package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * NHTSA VIN check-digit validation.
 * Port of COMVALD0.cbl — validates 17-character VIN using the standard
 * transliteration table and positional weight algorithm.
 */
@Component
public class VinValidator {

    /** Positional weights per NHTSA specification (positions 1-17). */
    private static final int[] WEIGHTS = {8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2};

    /** Transliteration map: letter -> numeric value. I, O, Q are intentionally absent. */
    private static final Map<Character, Integer> TRANSLITERATION = Map.ofEntries(
            Map.entry('A', 1), Map.entry('B', 2), Map.entry('C', 3),
            Map.entry('D', 4), Map.entry('E', 5), Map.entry('F', 6),
            Map.entry('G', 7), Map.entry('H', 8),
            Map.entry('J', 1), Map.entry('K', 2), Map.entry('L', 3),
            Map.entry('M', 4), Map.entry('N', 5), Map.entry('P', 7),
            Map.entry('R', 9),
            Map.entry('S', 2), Map.entry('T', 3), Map.entry('U', 4),
            Map.entry('V', 5), Map.entry('W', 6), Map.entry('X', 7),
            Map.entry('Y', 8), Map.entry('Z', 9)
    );

    /**
     * Validate a VIN using the NHTSA check-digit algorithm.
     *
     * @param vin the 17-character Vehicle Identification Number
     * @return validation result with error details if invalid
     */
    public VinValidationResult validate(String vin) {
        if (vin == null || vin.isBlank()) {
            return VinValidationResult.failure("VIN_EMPTY", "VIN must not be null or blank");
        }

        String normalized = vin.toUpperCase().trim();

        // 1. Check length
        if (normalized.length() != 17) {
            return VinValidationResult.failure("VIN_LENGTH",
                    "VIN must be exactly 17 characters, got " + normalized.length());
        }

        // 2. Check for invalid characters I, O, Q
        for (int i = 0; i < normalized.length(); i++) {
            char ch = normalized.charAt(i);
            if (ch == 'I' || ch == 'O' || ch == 'Q') {
                return VinValidationResult.failure("VIN_INVALID_CHAR",
                        "VIN contains invalid character '" + ch + "' at position " + (i + 1));
            }
        }

        // 3-5. Transliterate, multiply by weight, and sum
        int sum = 0;
        for (int i = 0; i < 17; i++) {
            char ch = normalized.charAt(i);
            int value;
            if (Character.isDigit(ch)) {
                value = ch - '0';
            } else if (TRANSLITERATION.containsKey(ch)) {
                value = TRANSLITERATION.get(ch);
            } else {
                return VinValidationResult.failure("VIN_INVALID_CHAR",
                        "VIN contains unrecognized character '" + ch + "' at position " + (i + 1));
            }
            sum += value * WEIGHTS[i];
        }

        // 6. Remainder mod 11
        int remainder = sum % 11;

        // 7. Expected check digit: remainder 10 -> 'X', else the digit itself
        char expectedCheckDigit = (remainder == 10) ? 'X' : (char) ('0' + remainder);

        // 8. Compare with position 9 (index 8)
        char actualCheckDigit = normalized.charAt(8);
        if (actualCheckDigit != expectedCheckDigit) {
            return VinValidationResult.failure("VIN_CHECK_DIGIT",
                    "Check digit mismatch: expected '" + expectedCheckDigit
                            + "' at position 9, found '" + actualCheckDigit + "'");
        }

        return VinValidationResult.success();
    }
}
