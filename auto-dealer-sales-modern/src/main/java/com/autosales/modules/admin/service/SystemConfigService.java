package com.autosales.modules.admin.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.SystemConfigRequest;
import com.autosales.modules.admin.dto.SystemConfigResponse;
import com.autosales.modules.admin.entity.SystemConfig;
import com.autosales.modules.admin.repository.SystemConfigRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for system configuration parameter management.
 * Port of ADMCFG00.cbl — system configuration maintenance transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
public class SystemConfigService {

    private final SystemConfigRepository repository;
    private final ResponseFormatter responseFormatter;

    public SystemConfigService(SystemConfigRepository repository,
                               ResponseFormatter responseFormatter) {
        this.repository = repository;
        this.responseFormatter = responseFormatter;
    }

    /**
     * Find all system configuration parameters (small table, no pagination needed).
     */
    public List<SystemConfigResponse> findAll() {
        log.debug("Finding all system config parameters");
        return repository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Find a single system configuration parameter by key.
     */
    public SystemConfigResponse findByKey(String key) {
        log.debug("Finding system config by key={}", key);
        SystemConfig entity = repository.findById(key)
                .orElseThrow(() -> new EntityNotFoundException("SystemConfig", key));
        return toResponse(entity);
    }

    /**
     * Update a system configuration parameter value.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "system_config", keyExpression = "#key")
    public SystemConfigResponse update(String key, SystemConfigRequest request) {
        log.info("Updating system config key={}", key);

        SystemConfig existing = repository.findById(key)
                .orElseThrow(() -> new EntityNotFoundException("SystemConfig", key));

        // Validate numeric keys require numeric values
        validateNumericConfig(key, request.getConfigValue());

        existing.setConfigValue(request.getConfigValue());
        if (request.getConfigDesc() != null) {
            existing.setConfigDesc(request.getConfigDesc());
        }

        // Set updatedBy from security context
        String updatedBy = SecurityContextHolder.getContext().getAuthentication() != null
                ? SecurityContextHolder.getContext().getAuthentication().getName()
                : "SYSTEM";
        existing.setUpdatedBy(updatedBy);
        existing.setUpdatedTs(LocalDateTime.now());

        SystemConfig saved = repository.save(existing);
        log.info("Updated system config key={} by user={}", saved.getConfigKey(), updatedBy);
        return toResponse(saved);
    }

    private void validateNumericConfig(String key, String value) {
        String upperKey = key.toUpperCase();
        if (upperKey.contains("NUMBER") || upperKey.contains("FREQ") || upperKey.contains("DAYS")) {
            try {
                Long.parseLong(value.trim());
            } catch (NumberFormatException e) {
                throw new BusinessValidationException(
                        "Configuration key '" + key + "' requires a numeric value, but received: " + value);
            }
        }
    }

    private SystemConfigResponse toResponse(SystemConfig entity) {
        return SystemConfigResponse.builder()
                .configKey(entity.getConfigKey())
                .configValue(entity.getConfigValue())
                .configDesc(entity.getConfigDesc())
                .updatedTs(entity.getUpdatedTs())
                .build();
    }
}
