package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.PurgeResultResponse;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.registration.entity.RecallNotification;
import com.autosales.modules.registration.entity.Registration;
import com.autosales.modules.registration.repository.RecallNotificationRepository;
import com.autosales.modules.registration.repository.RegistrationRepository;
import com.autosales.common.audit.AuditLog;
import com.autosales.common.audit.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Purge/archive processing service.
 * Port of BATPUR00.cbl — three-phase quarterly data housekeeping:
 * Phase 1: Archive completed registrations older than 2 years (Wave 6 dep)
 * Phase 2: Purge audit log entries older than 3 years (batched deletes)
 * Phase 3: Purge expired recall notifications older than 1 year (Wave 6 dep)
 *
 * Legacy used batched deletes of 500 rows to avoid DB2 lock escalation.
 * Modern equivalent uses Spring Data batch operations.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class PurgeBatchService {

    private static final String PROGRAM_ID = "BATPUR00";
    private static final int AUDIT_RETENTION_YEARS = 3;
    private static final int BATCH_SIZE = 500;

    private final BatchControlRepository batchControlRepository;
    private final AuditLogRepository auditLogRepository;
    private final RegistrationRepository registrationRepository;
    private final RecallNotificationRepository recallNotificationRepository;

    // ── BATPUR00: Run Purge Processing ────────────────────────────────

    @Transactional
    public BatchRunResult runPurge() {
        log.info("BATPUR00: Starting purge/archive processing");
        LocalDateTime startedAt = LocalDateTime.now();
        List<String> phases = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        int totalProcessed = 0;

        // Phase 1 — Count registrations older than 2 years (archival candidate identification)
        int phase1Count = countArchivalCandidates();
        phases.add("Phase 1: Registration archival candidates — " + phase1Count + " registrations older than 2 years");
        totalProcessed += phase1Count;

        // Phase 2 — Purge audit logs older than 3 years
        int phase2Count = purgeAuditLogs();
        phases.add("Phase 2: Audit logs purged — " + phase2Count);
        totalProcessed += phase2Count;

        // Phase 3 — Purge recall notifications older than 1 year
        int phase3Count = purgeOldRecallNotifications();
        phases.add("Phase 3: Notification purge — " + phase3Count + " notifications deleted");
        totalProcessed += phase3Count;

        updateBatchControl(totalProcessed);

        log.info("BATPUR00: Completed — {} records purged", totalProcessed);
        return BatchRunResult.builder()
                .programId(PROGRAM_ID)
                .status("OK")
                .recordsProcessed(totalProcessed)
                .recordsError(0)
                .startedAt(startedAt)
                .completedAt(LocalDateTime.now())
                .phases(phases)
                .warnings(warnings)
                .build();
    }

    public PurgeResultResponse getPurgePreview() {
        LocalDateTime auditCutoff = LocalDateTime.now().minusYears(AUDIT_RETENTION_YEARS);
        long auditCount = auditLogRepository.findAll().stream()
                .filter(a -> a.getAuditTs() != null && a.getAuditTs().isBefore(auditCutoff))
                .count();

        LocalDateTime regCutoff = LocalDateTime.now().minusYears(2);
        long regCount = registrationRepository.findAll().stream()
                .filter(r -> r.getCreatedTs() != null && r.getCreatedTs().isBefore(regCutoff))
                .count();

        LocalDate notifCutoff = LocalDate.now().minusYears(1);
        long notifCount = recallNotificationRepository.findAll().stream()
                .filter(n -> n.getNotifDate() != null && n.getNotifDate().isBefore(notifCutoff))
                .count();

        return PurgeResultResponse.builder()
                .executedAt(LocalDateTime.now())
                .registrationsArchived((int) regCount)
                .auditLogsPurged((int) auditCount)
                .notificationsPurged((int) notifCount)
                .status("PREVIEW")
                .build();
    }

    /**
     * Phase 2: Delete audit log entries older than 3 years.
     * Legacy: FETCH FIRST 500 ROWS ONLY loop to avoid lock escalation.
     * Modern: Batched delete in groups of BATCH_SIZE.
     */
    int purgeAuditLogs() {
        LocalDateTime cutoff = LocalDateTime.now().minusYears(AUDIT_RETENTION_YEARS);
        List<AuditLog> oldLogs = auditLogRepository.findAll().stream()
                .filter(a -> a.getAuditTs() != null && a.getAuditTs().isBefore(cutoff))
                .toList();

        int totalPurged = 0;
        // Process in batches of BATCH_SIZE (preserving the legacy anti-lock-escalation pattern)
        for (int i = 0; i < oldLogs.size(); i += BATCH_SIZE) {
            int end = Math.min(i + BATCH_SIZE, oldLogs.size());
            List<AuditLog> batch = oldLogs.subList(i, end);
            auditLogRepository.deleteAll(batch);
            totalPurged += batch.size();
            log.debug("BATPUR00: Purged batch of {} audit logs", batch.size());
        }
        return totalPurged;
    }

    /**
     * Phase 1: Count registrations older than 2 years for archival candidacy.
     * Does not actually delete — real archival is complex and requires
     * cascading to related tables. This counts candidates for reporting.
     * Ported from BATPUR00 ARCHIVE-REGISTRATIONS paragraph.
     */
    int countArchivalCandidates() {
        LocalDateTime twoYearsAgo = LocalDateTime.now().minusYears(2);
        long count = registrationRepository.findAll().stream()
                .filter(r -> r.getCreatedTs() != null && r.getCreatedTs().isBefore(twoYearsAgo))
                .count();
        log.info("BATPUR00: Found {} registrations older than 2 years (archival candidates)", count);
        return (int) count;
    }

    /**
     * Phase 3: Delete recall notifications older than 1 year.
     * Ported from BATPUR00 PURGE-NOTIFICATIONS paragraph.
     */
    int purgeOldRecallNotifications() {
        LocalDate oneYearAgo = LocalDate.now().minusYears(1);
        List<RecallNotification> oldNotifications = recallNotificationRepository.findAll().stream()
                .filter(n -> n.getNotifDate() != null && n.getNotifDate().isBefore(oneYearAgo))
                .toList();

        int totalPurged = 0;
        for (int i = 0; i < oldNotifications.size(); i += BATCH_SIZE) {
            int end = Math.min(i + BATCH_SIZE, oldNotifications.size());
            List<RecallNotification> batch = oldNotifications.subList(i, end);
            recallNotificationRepository.deleteAll(batch);
            totalPurged += batch.size();
            log.debug("BATPUR00: Purged batch of {} recall notifications", batch.size());
        }
        log.info("BATPUR00: Purged {} recall notifications older than 1 year", totalPurged);
        return totalPurged;
    }

    private void updateBatchControl(int recordsProcessed) {
        LocalDateTime now = LocalDateTime.now();
        BatchControl control = batchControlRepository.findById(PROGRAM_ID)
                .orElse(BatchControl.builder()
                        .programId(PROGRAM_ID)
                        .recordsProcessed(0)
                        .runStatus("OK")
                        .createdTs(now)
                        .updatedTs(now)
                        .build());
        control.setLastRunDate(LocalDate.now());
        control.setRecordsProcessed(recordsProcessed);
        control.setRunStatus("OK");
        control.setUpdatedTs(now);
        batchControlRepository.save(control);
    }
}
