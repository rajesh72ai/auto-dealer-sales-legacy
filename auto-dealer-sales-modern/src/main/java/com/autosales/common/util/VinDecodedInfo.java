package com.autosales.common.util;

/**
 * Decoded VIN component information.
 * Port of COMVINL0.cbl VIN decode output area.
 */
public record VinDecodedInfo(
        String wmi,
        String countryOfOrigin,
        String manufacturer,
        int modelYear,
        String plantCode,
        String sequentialNumber
) {
}
