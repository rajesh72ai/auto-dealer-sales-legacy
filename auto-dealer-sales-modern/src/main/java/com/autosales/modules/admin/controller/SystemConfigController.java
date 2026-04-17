package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.SystemConfigRequest;
import com.autosales.modules.admin.dto.SystemConfigResponse;
import com.autosales.modules.admin.service.SystemConfigService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for system configuration administration.
 * Port of SYSADM00.cbl — system configuration parameter maintenance (list/update only, no create/delete).
 */
@RestController
@RequestMapping("/api/admin/config")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class SystemConfigController {

    private final SystemConfigService service;
    private final ResponseFormatter responseFormatter;

    public SystemConfigController(SystemConfigService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<SystemConfigResponse>>> list() {
        log.info("Listing all system configuration entries");
        List<SystemConfigResponse> configs = service.findAll();
        return ResponseEntity.ok(responseFormatter.success(configs));
    }

    @GetMapping("/{key}")
    public ResponseEntity<ApiResponse<SystemConfigResponse>> getByKey(@PathVariable String key) {
        log.info("Getting system config by key: {}", key);
        SystemConfigResponse response = service.findByKey(key);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PutMapping("/{key}")
    public ResponseEntity<ApiResponse<SystemConfigResponse>> update(
            @PathVariable String key,
            @Valid @RequestBody SystemConfigRequest request) {
        log.info("Updating system config: {}", key);
        SystemConfigResponse response = service.update(key, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Configuration updated successfully"));
    }
}
