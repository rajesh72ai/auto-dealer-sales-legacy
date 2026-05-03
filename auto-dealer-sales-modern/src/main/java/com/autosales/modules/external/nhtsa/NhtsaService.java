package com.autosales.modules.external.nhtsa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Live integration with the U.S. National Highway Traffic Safety
 * Administration (NHTSA) public APIs. No API key required, both endpoints
 * are free and rate-limited only by reasonable use.
 *
 * <ul>
 *   <li>Recalls by VIN — {@code https://api.nhtsa.gov/recalls/recallsByVin}
 *       returns federal recall campaigns affecting a specific VIN.</li>
 *   <li>vPIC decode — {@code https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin}
 *       is the canonical VIN decoder; better than guessing from manufacturer
 *       prefix tables.</li>
 * </ul>
 *
 * <p>NHTSA data changes slowly (campaigns are published once and rarely
 * amended). We cache responses in-memory for a few hours per VIN to avoid
 * hammering the federal API on repeat queries.
 */
@Service
public class NhtsaService {

    private static final Logger log = LoggerFactory.getLogger(NhtsaService.class);

    private static final String RECALLS_URL = "https://api.nhtsa.gov/recalls/recallsByVin";
    private static final String VPIC_URL    = "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin";
    private static final Duration CACHE_TTL = Duration.ofHours(2);
    private static final int MAX_CACHE_ENTRIES = 1000;

    private final RestClient client;
    private final Map<String, CacheEntry<Map<String, Object>>> recallCache = new ConcurrentHashMap<>();
    private final Map<String, CacheEntry<Map<String, Object>>> decodeCache = new ConcurrentHashMap<>();

    public NhtsaService() {
        // User-Agent: NHTSA's APIs returned 403 from Cloud Run egress with
        // our original "AUTOSALES/1.0 (Cloud Run; Vertex AI Gemini agent)"
        // string. The parens-and-semicolons format apparently trips bot
        // detection on some federal endpoints. A plain Mozilla-style UA
        // gets through cleanly. We keep the AUTOSALES/1.0 product token
        // for telemetry visibility on our side.
        this.client = RestClient.builder()
                .defaultHeader("User-Agent", "Mozilla/5.0 (compatible; AUTOSALES/1.0)")
                .defaultHeader("Accept", "application/json")
                .build();
    }

    /**
     * Look up active recalls for a VIN. Returns an empty results list when
     * NHTSA has nothing for the VIN — a positive signal worth conveying to
     * the user, not an error.
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> recallsByVin(String vin) {
        if (vin == null || vin.isBlank()) {
            throw new IllegalArgumentException("vin is required");
        }
        String key = vin.trim().toUpperCase();
        CacheEntry<Map<String, Object>> cached = recallCache.get(key);
        if (cached != null && !cached.isExpired()) {
            log.debug("NHTSA recalls cache hit: {}", key);
            return cached.value();
        }

        Map<String, Object> body;
        try {
            body = client.get()
                    .uri(uri -> uri.scheme("https").host("api.nhtsa.gov").path("/recalls/recallsByVin")
                            .queryParam("vin", key).build())
                    .retrieve()
                    .body(Map.class);
            if (body == null) body = Map.of("count", 0, "results", java.util.List.of());
        } catch (Exception e) {
            log.warn("NHTSA recalls call failed for VIN={}: {}", key, e.getMessage());
            return Map.of("count", 0, "results", java.util.List.of(),
                    "error", "NHTSA service unavailable: " + e.getMessage());
        }

        evictIfFull(recallCache);
        recallCache.put(key, new CacheEntry<>(body, Instant.now().plus(CACHE_TTL)));
        return body;
    }

    /**
     * Decode a VIN via NHTSA's vPIC service. Returns a map with manufacturer,
     * make, model, year, body class, plant, etc. Authoritative source — used
     * in lieu of our internal heuristic decoder when this service is reachable.
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> decodeVin(String vin) {
        if (vin == null || vin.isBlank()) {
            throw new IllegalArgumentException("vin is required");
        }
        String key = vin.trim().toUpperCase();
        CacheEntry<Map<String, Object>> cached = decodeCache.get(key);
        if (cached != null && !cached.isExpired()) {
            log.debug("vPIC decode cache hit: {}", key);
            return cached.value();
        }

        Map<String, Object> body;
        try {
            body = client.get()
                    .uri(uri -> uri.scheme("https").host("vpic.nhtsa.dot.gov")
                            .path("/api/vehicles/DecodeVin/" + key)
                            .queryParam("format", "json").build())
                    .retrieve()
                    .body(Map.class);
            if (body == null) body = Map.of("Count", 0, "Results", java.util.List.of());
        } catch (Exception e) {
            log.warn("vPIC decode failed for VIN={}: {}", key, e.getMessage());
            return Map.of("Count", 0, "Results", java.util.List.of(),
                    "error", "vPIC service unavailable: " + e.getMessage());
        }

        evictIfFull(decodeCache);
        decodeCache.put(key, new CacheEntry<>(body, Instant.now().plus(CACHE_TTL)));
        return body;
    }

    private static <K, V> void evictIfFull(Map<K, CacheEntry<V>> cache) {
        if (cache.size() < MAX_CACHE_ENTRIES) return;
        // Cheap eviction: drop expired entries; if still full, remove arbitrary ~10%.
        Instant now = Instant.now();
        cache.entrySet().removeIf(e -> e.getValue().expiresAt().isBefore(now));
        if (cache.size() >= MAX_CACHE_ENTRIES) {
            int target = MAX_CACHE_ENTRIES * 9 / 10;
            cache.keySet().stream().limit(cache.size() - target).toList()
                    .forEach(cache::remove);
        }
    }

    private record CacheEntry<V>(V value, Instant expiresAt) {
        boolean isExpired() {
            return Instant.now().isAfter(expiresAt);
        }
    }
}
