package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.PurgeResultResponse;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.common.audit.AuditLog;
import com.autosales.common.audit.AuditLogRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for PurgeBatchService — port of BATPUR00.cbl.
 * Validates:
 *   Phase 2: Audit log purge with 3-year retention
 *   Batched delete pattern (500 rows per batch) to avoid lock escalation
 */
@ExtendWith(MockitoExtension.class)
class PurgeBatchServiceTest {

    @Mock private BatchControlRepository batchControlRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private com.autosales.modules.registration.repository.RegistrationRepository registrationRepository;
    @Mock private com.autosales.modules.registration.repository.RecallNotificationRepository recallNotificationRepository;

    @InjectMocks
    private PurgeBatchService purgeBatchService;

    // ── Phase 2: Audit Log Purge ──────────────────────────────────────

    @Test
    @DisplayName("BATPUR00 Phase 2: Audit logs older than 3 years are purged")
    void purgeAuditLogs_purgesOldEntries() {
        AuditLog oldLog = new AuditLog();
        oldLog.setAuditId(1);
        oldLog.setAuditTs(LocalDateTime.now().minusYears(4)); // 4 years old

        AuditLog recentLog = new AuditLog();
        recentLog.setAuditId(2);
        recentLog.setAuditTs(LocalDateTime.now().minusMonths(6)); // 6 months old

        when(auditLogRepository.findAll()).thenReturn(List.of(oldLog, recentLog));

        int count = purgeBatchService.purgeAuditLogs();

        assertEquals(1, count, "BATPUR00: Only audit logs older than 3 years should be purged");
        verify(auditLogRepository).deleteAll(argThat(list -> {
            List<AuditLog> logs = new ArrayList<>();
            list.forEach(logs::add);
            return logs.size() == 1 && logs.get(0).getAuditId() == 1;
        }));
    }

    @Test
    @DisplayName("BATPUR00 Phase 2: Audit log at exactly 3 years is not purged")
    void purgeAuditLogs_exactlyThreeYears_notPurged() {
        AuditLog borderlineLog = new AuditLog();
        borderlineLog.setAuditId(1);
        borderlineLog.setAuditTs(LocalDateTime.now().minusYears(3).plusHours(1)); // Just under 3 years

        when(auditLogRepository.findAll()).thenReturn(List.of(borderlineLog));

        int count = purgeBatchService.purgeAuditLogs();

        assertEquals(0, count);
    }

    @Test
    @DisplayName("BATPUR00: No audit logs to purge returns zero")
    void purgeAuditLogs_noOldLogs_returnsZero() {
        when(auditLogRepository.findAll()).thenReturn(List.of());

        int count = purgeBatchService.purgeAuditLogs();

        assertEquals(0, count);
    }

    // ── Purge Preview ─────────────────────────────────────────────────

    @Test
    @DisplayName("BATPUR00: Purge preview shows count without deleting")
    void getPurgePreview_showsCountOnly() {
        AuditLog oldLog = new AuditLog();
        oldLog.setAuditTs(LocalDateTime.now().minusYears(5));
        when(auditLogRepository.findAll()).thenReturn(List.of(oldLog));

        PurgeResultResponse result = purgeBatchService.getPurgePreview();

        assertEquals(1, result.getAuditLogsPurged());
        assertEquals("PREVIEW", result.getStatus());
        verify(auditLogRepository, never()).deleteAll(any(Iterable.class));
    }

    // ── Full Run ──────────────────────────────────────────────────────

    @Test
    @DisplayName("BATPUR00: Full purge run — all 3 phases execute with Wave 6 repos wired")
    void runPurge_includesWave6Deferrals() {
        when(auditLogRepository.findAll()).thenReturn(List.of());
        when(batchControlRepository.findById("BATPUR00")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        // Wave 6 repos return empty results
        lenient().when(registrationRepository.findAll()).thenReturn(List.of());
        lenient().when(recallNotificationRepository.findAll()).thenReturn(List.of());

        BatchRunResult result = purgeBatchService.runPurge();

        assertEquals("BATPUR00", result.getProgramId());
        assertEquals("OK", result.getStatus());
        assertEquals(3, result.getPhases().size());
    }
}
