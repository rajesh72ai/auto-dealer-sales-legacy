package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link VinValidator} — NHTSA check-digit validation.
 */
class VinValidatorTest {

    private VinValidator validator;

    @BeforeEach
    void setUp() {
        validator = new VinValidator();
    }

    @Test
    void testValidVin() {
        // 1HGBH41JXMN109186 is a well-known valid Honda VIN
        VinValidationResult result = validator.validate("1HGBH41JXMN109186");
        assertTrue(result.valid(), "Expected VIN to be valid");
        assertNull(result.errorCode());
    }

    @Test
    void testInvalidLengthTooShort() {
        VinValidationResult result = validator.validate("1HGBH41JX");
        assertFalse(result.valid());
        assertEquals("VIN_LENGTH", result.errorCode());
    }

    @Test
    void testInvalidLengthTooLong() {
        VinValidationResult result = validator.validate("1HGBH41JXMN109186XX");
        assertFalse(result.valid());
        assertEquals("VIN_LENGTH", result.errorCode());
    }

    @Test
    void testInvalidCharacterI() {
        // Replace a valid character with 'I' — forbidden in VINs
        VinValidationResult result = validator.validate("1HGBH41IXMN109186");
        assertFalse(result.valid());
        assertEquals("VIN_INVALID_CHAR", result.errorCode());
        assertTrue(result.errorMessage().contains("'I'"));
    }

    @Test
    void testInvalidCharacterO() {
        VinValidationResult result = validator.validate("1HGBH41OXMN109186");
        assertFalse(result.valid());
        assertEquals("VIN_INVALID_CHAR", result.errorCode());
        assertTrue(result.errorMessage().contains("'O'"));
    }

    @Test
    void testInvalidCharacterQ() {
        VinValidationResult result = validator.validate("1HGBH41QXMN109186");
        assertFalse(result.valid());
        assertEquals("VIN_INVALID_CHAR", result.errorCode());
        assertTrue(result.errorMessage().contains("'Q'"));
    }

    @Test
    void testBadCheckDigit() {
        // Change the check digit (position 9, index 8) from 'X' to '0'
        VinValidationResult result = validator.validate("1HGBH41J0MN109186");
        assertFalse(result.valid());
        assertEquals("VIN_CHECK_DIGIT", result.errorCode());
    }

    @Test
    void testAllNumericVin() {
        // 11111111111111111 — transliterate: all 1s, weights sum = 8+7+6+5+4+3+2+10+0+9+8+7+6+5+4+3+2 = 89
        // 89 % 11 = 1, so check digit (position 9) must be '1', which it is.
        VinValidationResult result = validator.validate("11111111111111111");
        assertTrue(result.valid(), "All-ones VIN should pass check-digit validation");
    }

    @Test
    void testNullInput() {
        VinValidationResult result = validator.validate(null);
        assertFalse(result.valid());
        assertEquals("VIN_EMPTY", result.errorCode());
    }

    @Test
    void testEmptyString() {
        VinValidationResult result = validator.validate("");
        assertFalse(result.valid());
        assertEquals("VIN_EMPTY", result.errorCode());
    }

    @Test
    void testCheckDigitX() {
        // We need a VIN where (sum % 11) == 10, meaning the check digit should be 'X'.
        // 1HGBH41JXMN109186 has check digit 'X' — this is already tested above,
        // but let's explicitly verify the 'X' path by confirming the check digit char.
        VinValidationResult result = validator.validate("1HGBH41JXMN109186");
        assertTrue(result.valid());
        // Position 9 (index 8) is 'X', which means the computed remainder was 10
        assertEquals('X', "1HGBH41JXMN109186".charAt(8));
    }
}
