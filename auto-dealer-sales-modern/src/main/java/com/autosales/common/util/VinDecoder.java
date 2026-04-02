package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Decode VIN components: country of origin, manufacturer, model year,
 * assembly plant, and sequential production number.
 * Port of COMVINL0.cbl — VIN lookup/decode routine.
 */
@Component
public class VinDecoder {

    /** Country of origin by first VIN character. */
    private static final Map<Character, String> COUNTRY_MAP = Map.ofEntries(
            Map.entry('1', "United States"), Map.entry('2', "Canada"),
            Map.entry('3', "Mexico"), Map.entry('4', "United States"),
            Map.entry('5', "United States"),
            Map.entry('J', "Japan"), Map.entry('K', "South Korea"),
            Map.entry('S', "United Kingdom"), Map.entry('W', "Germany"),
            Map.entry('Z', "Italy"), Map.entry('L', "China"),
            Map.entry('9', "Brazil"), Map.entry('Y', "Sweden/Finland")
    );

    /** Manufacturer by WMI prefix (first 2 characters). */
    private static final Map<String, String> MANUFACTURER_MAP = Map.ofEntries(
            Map.entry("1G", "General Motors"), Map.entry("1F", "Ford"),
            Map.entry("1C", "Chrysler"), Map.entry("1H", "Honda (US)"),
            Map.entry("1N", "Nissan (US)"), Map.entry("1L", "Lincoln"),
            Map.entry("2T", "Toyota (Canada)"), Map.entry("2G", "General Motors (Canada)"),
            Map.entry("2F", "Ford (Canada)"),
            Map.entry("3N", "Nissan (Mexico)"), Map.entry("3G", "General Motors (Mexico)"),
            Map.entry("3F", "Ford (Mexico)"),
            Map.entry("JT", "Toyota (Japan)"), Map.entry("JH", "Honda (Japan)"),
            Map.entry("JN", "Nissan (Japan)"), Map.entry("JM", "Mazda (Japan)"),
            Map.entry("KM", "Hyundai"), Map.entry("KN", "Kia"),
            Map.entry("WB", "BMW"), Map.entry("WA", "Audi"),
            Map.entry("WD", "Mercedes-Benz"), Map.entry("WF", "Ford (Germany)"),
            Map.entry("WV", "Volkswagen"), Map.entry("WP", "Porsche"),
            Map.entry("ZA", "Alfa Romeo"), Map.entry("ZF", "Ferrari"),
            Map.entry("SA", "Jaguar"), Map.entry("SJ", "Jaguar"),
            Map.entry("SC", "Lotus"), Map.entry("YV", "Volvo")
    );

    /**
     * Model year code at VIN position 10.
     * A=2010..H=2017, J=2018, K=2019, L=2020..N=2022,
     * P=2023, R=2024, S=2025, T=2026..Y=2030,
     * 1=2001..9=2009  (and the cycle repeats every 30 years).
     */
    private static final Map<Character, Integer> MODEL_YEAR_MAP = buildModelYearMap();

    private static Map<Character, Integer> buildModelYearMap() {
        // Using java.util.HashMap because Map.ofEntries has a 10-entry overload limit
        // and we need more entries than that.
        var map = new java.util.HashMap<Character, Integer>();
        // Digits 1-9 -> 2001-2009 (also 2031-2039 in the next cycle)
        for (int d = 1; d <= 9; d++) {
            map.put((char) ('0' + d), 2000 + d);
        }
        // Letters A-H -> 2010-2017
        map.put('A', 2010); map.put('B', 2011); map.put('C', 2012);
        map.put('D', 2013); map.put('E', 2014); map.put('F', 2015);
        map.put('G', 2016); map.put('H', 2017);
        // J-N -> 2018-2022 (skip I)
        map.put('J', 2018); map.put('K', 2019); map.put('L', 2020);
        map.put('M', 2021); map.put('N', 2022);
        // P -> 2023 (skip O)
        map.put('P', 2023);
        // R-Y -> 2024-2030 (skip Q)
        map.put('R', 2024); map.put('S', 2025); map.put('T', 2026);
        map.put('U', 2027); map.put('V', 2028); map.put('W', 2029);
        map.put('X', 2030); map.put('Y', 2030); // Y wraps to end of cycle
        return Map.copyOf(map);
    }

    /**
     * Decode a 17-character VIN into its component parts.
     *
     * @param vin the Vehicle Identification Number (must be 17 chars)
     * @return decoded VIN information
     * @throws IllegalArgumentException if VIN is null or not 17 characters
     */
    public VinDecodedInfo decode(String vin) {
        if (vin == null || vin.trim().length() != 17) {
            throw new IllegalArgumentException("VIN must be exactly 17 characters");
        }

        String normalized = vin.toUpperCase().trim();

        // WMI: positions 1-3
        String wmi = normalized.substring(0, 3);

        // Country of origin: position 1
        char countryChar = normalized.charAt(0);
        String countryOfOrigin = COUNTRY_MAP.getOrDefault(countryChar, "Unknown");

        // Manufacturer: first 2 characters of WMI
        String mfgPrefix = normalized.substring(0, 2);
        String manufacturer = MANUFACTURER_MAP.getOrDefault(mfgPrefix, "Unknown (" + mfgPrefix + ")");

        // Model year: position 10 (index 9)
        char yearCode = normalized.charAt(9);
        int modelYear = MODEL_YEAR_MAP.getOrDefault(yearCode, 0);

        // Assembly plant: position 11 (index 10)
        String plantCode = String.valueOf(normalized.charAt(10));

        // Sequential production number: positions 12-17 (index 11-16)
        String sequentialNumber = normalized.substring(11, 17);

        return new VinDecodedInfo(wmi, countryOfOrigin, manufacturer, modelYear, plantCode, sequentialNumber);
    }
}
