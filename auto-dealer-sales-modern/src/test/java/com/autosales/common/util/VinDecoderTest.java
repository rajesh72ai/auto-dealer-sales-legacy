package com.autosales.common.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for {@link VinDecoder} — VIN component decoding.
 */
class VinDecoderTest {

    private VinDecoder decoder;

    @BeforeEach
    void setUp() {
        decoder = new VinDecoder();
    }

    @Test
    void testDecodeUSManufactured() {
        // VIN starting with '1H' -> United States, Honda (US)
        VinDecodedInfo info = decoder.decode("1HGBH41JXMN109186");
        assertEquals("United States", info.countryOfOrigin());
        assertEquals("Honda (US)", info.manufacturer());
        assertEquals("1HG", info.wmi());
        assertEquals("109186", info.sequentialNumber());
    }

    @Test
    void testDecodeJapanManufactured() {
        // VIN starting with 'JT' -> Japan, Toyota (Japan)
        VinDecodedInfo info = decoder.decode("JTDKN3DU5A0000001");
        assertEquals("Japan", info.countryOfOrigin());
        assertEquals("Toyota (Japan)", info.manufacturer());
        assertEquals("JTD", info.wmi());
    }

    @Test
    void testDecodeGermanManufactured() {
        // VIN starting with 'WB' -> Germany, BMW
        VinDecodedInfo info = decoder.decode("WBAPH5C55BA000001");
        assertEquals("Germany", info.countryOfOrigin());
        assertEquals("BMW", info.manufacturer());
        assertEquals("WBA", info.wmi());
    }

    @Test
    void testModelYearDecode() {
        // Position 10 (index 9): 'M' -> 2021, 'A' -> 2010, 'R' -> 2024
        VinDecodedInfo infoM = decoder.decode("1HGBH41JXMN109186");
        assertEquals(2021, infoM.modelYear(), "Year code 'M' should decode to 2021");

        VinDecodedInfo infoA = decoder.decode("1HGBH41JXAN109186");
        assertEquals(2010, infoA.modelYear(), "Year code 'A' should decode to 2010");

        VinDecodedInfo infoR = decoder.decode("1HGBH41JXRN109186");
        assertEquals(2024, infoR.modelYear(), "Year code 'R' should decode to 2024");

        // Digit '9' -> 2009
        VinDecodedInfo info9 = decoder.decode("1HGBH41JX9N109186");
        assertEquals(2009, info9.modelYear(), "Year code '9' should decode to 2009");
    }
}
