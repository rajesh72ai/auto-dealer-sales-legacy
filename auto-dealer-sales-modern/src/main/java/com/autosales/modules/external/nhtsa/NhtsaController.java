package com.autosales.modules.external.nhtsa;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Public-facing wrapper around the NHTSA federal recall and vPIC decode
 * services. The agent's read tools {@code nhtsa_recall_lookup} and
 * {@code nhtsa_vin_decode} hit these endpoints (via {@code ToolExecutor}),
 * which in turn delegate to {@link NhtsaService} — so caching, error
 * handling, and rate-limit politeness all live in one place.
 */
@RestController
@RequestMapping("/api/nhtsa")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR','AGENT_SERVICE')")
public class NhtsaController {

    private final NhtsaService nhtsa;

    @GetMapping("/recalls")
    public ResponseEntity<Map<String, Object>> recalls(@RequestParam String vin) {
        return ResponseEntity.ok(nhtsa.recallsByVin(vin));
    }

    @GetMapping("/decode")
    public ResponseEntity<Map<String, Object>> decode(@RequestParam String vin) {
        return ResponseEntity.ok(nhtsa.decodeVin(vin));
    }
}
