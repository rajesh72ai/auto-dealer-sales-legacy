package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.registration.entity.RecallCampaign;
import com.autosales.modules.registration.entity.Warranty;
import com.autosales.modules.registration.repository.RecallCampaignRepository;
import com.autosales.modules.registration.repository.RecallVehicleRepository;
import com.autosales.modules.registration.repository.WarrantyRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

/**
 * Weekly batch processing service.
 * Port of BATWKL00.cbl — three-phase Sunday batch:
 * Phase 1: Age inventory (update DAYS_IN_STOCK on vehicles in dealer stock)
 * Phase 2: Generate warranty expiration notices (30-day lookahead)
 * Phase 3: Update recall campaign completion percentages
 *
 * Note: Phases 2 & 3 (warranty/recall) reference registration module tables
 * which are being built in Wave 6. This service implements Phase 1 (inventory
 * aging) which is fully within the batch module scope. Phases 2 & 3 are
 * stubbed with logging for future Wave 6 integration.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class WeeklyBatchService {

    private static final String PROGRAM_ID = "BATWKL00";

    private final BatchControlRepository batchControlRepository;
    private final VehicleRepository vehicleRepository;
    private final WarrantyRepository warrantyRepository;
    private final RecallCampaignRepository recallCampaignRepository;
    private final RecallVehicleRepository recallVehicleRepository;

    // ── BATWKL00: Run Weekly Processing ───────────────────────────────

    @Transactional
    public BatchRunResult runWeeklyProcessing() {
        log.info("BATWKL00: Starting weekly batch processing");
        LocalDateTime startedAt = LocalDateTime.now();
        List<String> phases = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        int totalProcessed = 0;

        // Phase 1 — Age inventory
        int phase1Count = ageInventory();
        phases.add("Phase 1: Inventory aged — " + phase1Count + " vehicles updated");
        totalProcessed += phase1Count;

        // Phase 2 — Warranty expiration notices (30-day lookahead)
        int phase2Count = processWarrantyExpiryNotices();
        phases.add("Phase 2: Warranty notices — " + phase2Count + " expiring within 30 days");
        totalProcessed += phase2Count;

        // Phase 3 — Recall campaign completion percentages
        int phase3Count = updateRecallCompletionStats();
        phases.add("Phase 3: Recall completion — " + phase3Count + " campaigns evaluated");
        totalProcessed += phase3Count;

        updateBatchControl(totalProcessed);

        log.info("BATWKL00: Completed — {} records processed", totalProcessed);
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

    /**
     * Phase 1: For each vehicle in status AV/HD/DL with a receive date,
     * calculate DAYS(CURRENT DATE) - DAYS(RECEIVE_DATE) and update DAYS_IN_STOCK.
     * Ported from BATWKL00 AGE-INVENTORY paragraph.
     */
    int ageInventory() {
        List<String> stockStatuses = List.of("AV", "HD", "DL");
        LocalDate today = LocalDate.now();
        int count = 0;

        List<Vehicle> vehicles = vehicleRepository.findAll().stream()
                .filter(v -> stockStatuses.contains(v.getVehicleStatus()))
                .filter(v -> v.getReceiveDate() != null)
                .toList();

        for (Vehicle vehicle : vehicles) {
            short daysInStock = (short) ChronoUnit.DAYS.between(vehicle.getReceiveDate(), today);
            vehicle.setDaysInStock(daysInStock);
            vehicle.setUpdatedTs(LocalDateTime.now());
            vehicleRepository.save(vehicle);
            count++;
        }
        return count;
    }

    /**
     * Phase 2: Query warranties expiring within 30 days and log count.
     * Ported from BATWKL00 WARRANTY-EXPIRY-NOTICES paragraph.
     */
    int processWarrantyExpiryNotices() {
        LocalDate today = LocalDate.now();
        LocalDate thirtyDaysOut = today.plusDays(30);

        List<Warranty> expiring = warrantyRepository.findAll().stream()
                .filter(w -> "Y".equals(w.getActiveFlag()))
                .filter(w -> w.getExpiryDate() != null)
                .filter(w -> !w.getExpiryDate().isBefore(today) && !w.getExpiryDate().isAfter(thirtyDaysOut))
                .toList();

        log.info("BATWKL00: Processed {} warranty expiry notices (expiring within 30 days)", expiring.size());
        return expiring.size();
    }

    /**
     * Phase 3: For each active recall campaign, calculate completion percentage.
     * Ported from BATWKL00 RECALL-COMPLETION paragraph.
     */
    int updateRecallCompletionStats() {
        List<RecallCampaign> activeCampaigns = recallCampaignRepository.findByCampaignStatus("A",
                org.springframework.data.domain.Pageable.unpaged()).getContent();

        for (RecallCampaign campaign : activeCampaigns) {
            long totalVehicles = recallVehicleRepository.findByRecallId(campaign.getRecallId()).size();
            long completedVehicles = recallVehicleRepository.countByRecallIdAndRecallStatus(
                    campaign.getRecallId(), "C");

            double pct = totalVehicles > 0 ? (completedVehicles * 100.0 / totalVehicles) : 0.0;
            log.info("BATWKL00: Recall {}: {}/{} = {}% complete",
                    campaign.getRecallId(), completedVehicles, totalVehicles,
                    String.format("%.1f", pct));
        }

        log.info("BATWKL00: Evaluated {} active recall campaigns", activeCampaigns.size());
        return activeCampaigns.size();
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
