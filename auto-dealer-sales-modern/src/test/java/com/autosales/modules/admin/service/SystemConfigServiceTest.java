package com.autosales.modules.admin.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.SystemConfigRequest;
import com.autosales.modules.admin.dto.SystemConfigResponse;
import com.autosales.modules.admin.entity.SystemConfig;
import com.autosales.modules.admin.repository.SystemConfigRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SystemConfigServiceTest {

    @Mock
    private SystemConfigRepository repository;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private SystemConfigService systemConfigService;

    private SystemConfig buildConfig(String key, String value) {
        return SystemConfig.builder()
                .configKey(key)
                .configValue(value)
                .configDesc("Test config description")
                .updatedBy("SYSTEM")
                .updatedTs(LocalDateTime.of(2025, 1, 1, 12, 0))
                .build();
    }

    @Test
    void testFindAll() {
        SystemConfig c1 = buildConfig("MAX_RETRY_NUMBER", "3");
        SystemConfig c2 = buildConfig("APP_NAME", "AUTOSALES");
        when(repository.findAll()).thenReturn(List.of(c1, c2));

        List<SystemConfigResponse> results = systemConfigService.findAll();

        assertNotNull(results);
        assertEquals(2, results.size());
        assertEquals("MAX_RETRY_NUMBER", results.get(0).getConfigKey());
        assertEquals("APP_NAME", results.get(1).getConfigKey());
        verify(repository).findAll();
    }

    @Test
    void testUpdate_success() {
        SystemConfig existing = buildConfig("APP_NAME", "AUTOSALES");
        when(repository.findById("APP_NAME")).thenReturn(Optional.of(existing));
        when(repository.save(any(SystemConfig.class))).thenAnswer(inv -> inv.getArgument(0));

        // Set up security context
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken("admin_user", "password"));

        try {
            SystemConfigRequest request = SystemConfigRequest.builder()
                    .configValue("AUTOSALES_V2")
                    .configDesc("Updated app name")
                    .build();

            SystemConfigResponse response = systemConfigService.update("APP_NAME", request);

            assertNotNull(response);
            assertEquals("AUTOSALES_V2", response.getConfigValue());
            assertEquals("Updated app name", response.getConfigDesc());
            verify(repository).save(existing);
        } finally {
            SecurityContextHolder.clearContext();
        }
    }

    @Test
    void testUpdate_numericKeyWithNonNumericValue() {
        // Key containing "NUMBER" requires numeric value
        SystemConfig existing = buildConfig("MAX_RETRY_NUMBER", "3");
        when(repository.findById("MAX_RETRY_NUMBER")).thenReturn(Optional.of(existing));

        SystemConfigRequest request = SystemConfigRequest.builder()
                .configValue("abc")
                .build();

        assertThrows(BusinessValidationException.class,
                () -> systemConfigService.update("MAX_RETRY_NUMBER", request));
        verify(repository, never()).save(any());
    }
}
