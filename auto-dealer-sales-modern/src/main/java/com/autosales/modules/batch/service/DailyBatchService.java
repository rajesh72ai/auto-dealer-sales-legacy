package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.DailySalesSummaryResponse;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.entity.DailySalesSummary;
import com.autosales.modules.batch.entity.DailySalesSummaryId;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.batch.repository.DailySalesSummaryRepository;
import com.autosales.modules.floorplan.entity.FloorPlanInterest;
import com.autosales.modules.floorplan.entity.FloorPlanLender;
import com.autosales.modules.floorplan.entity.FloorPlanVehicle;
import com.autosales.modules.floorplan.repository.FloorPlanInterestRepository;
import com.autosales.modules.floorplan.repository.FloorPlanLenderRepository;
import com.autosales.modules.floorplan.repository.FloorPlanVehicleRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Daily end-of-day batch processing service.
 * Port of BATDLY00.cbl — three-phase nightly batch:
 * Phase 1: Update delivered vehicles from STOCK to SOLD
 * Phase 2: Expire pending deals older than 30 days
 * Phase 3: Calculate daily floor plan interest accrual
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class DailyBatchService {

    private static final String PROGRAM_ID = "BATDLY00";
    private static final int DEAL_EXPIRY_DAYS = 30;

    private final DailySalesSummaryRepository dailySalesSummaryRepository;
    private final BatchControlRepository batchControlRepository;
    private final VehicleRepository vehicleRepository;
    private final SalesDealRepository salesDealRepository;
    private final FloorPlanVehicleRepository floorPlanVehicleRepository;
    private final FloorPlanLenderRepository floorPlanLenderRepository;
    private final FloorPlanInterestRepository floorPlanInterestRepository;

    // ── Query Methods (read-only, no @Auditable) ──────────────────────

    public List<DailySalesSummaryResponse> getDailySummaries(String dealerCode,
                                                             LocalDate startDate,
                                                             LocalDate endDate) {
        return dailySalesSummaryRepository
                .findByDealerCodeAndSummaryDateBetweenOrderBySummaryDateDesc(dealerCode, startDate, endDate)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<DailySalesSummaryResponse> getSummariesByDate(LocalDate date) {
        return dailySalesSummaryRepository.findBySummaryDate(date)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ── BATDLY00: Run Daily End-of-Day ────────────────────────────────

    @Transactional
    public BatchRunResult runDailyEndOfDay() {
        log.info("BATDLY00: Starting daily end-of-day processing");
        LocalDateTime startedAt = LocalDateTime.now();
        List<String> phases = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        int totalProcessed = 0;

        // Phase 1 — Update delivered vehicles to SOLD (VEHICLE_STATUS = 'SD')
        int phase1Count = processDeliveredVehicles();
        phases.add("Phase 1: Delivered vehicles marked SOLD — " + phase1Count);
        totalProcessed += phase1Count;

        // Phase 2 — Expire pending deals older than 30 days
        int phase2Count = expirePendingDeals();
        phases.add("Phase 2: Pending deals expired — " + phase2Count);
        totalProcessed += phase2Count;

        // Phase 3 — Calculate daily floor plan interest accrual
        int phase3Count = accrueFloorPlanInterest(warnings);
        phases.add("Phase 3: Floor plan interest accrued — " + phase3Count);
        totalProcessed += phase3Count;

        // Update batch control
        updateBatchControl(totalProcessed);

        log.info("BATDLY00: Completed — {} records processed", totalProcessed);
        return BatchRunResult.builder()
                .programId(PROGRAM_ID)
                .status("OK")
                .recordsProcessed(totalProcessed)
                .recordsError(warnings.size())
                .startedAt(startedAt)
                .completedAt(LocalDateTime.now())
                .phases(phases)
                .warnings(warnings)
                .build();
    }

    /**
     * Phase 1: Find vehicles with delivered deals still in stock status,
     * update to SOLD ('SD'). Ported from BATDLY00 PROCESS-DELIVERED-VEHICLES.
     */
    int processDeliveredVehicles() {
        // Find deals delivered today that are in DL status
        LocalDate today = LocalDate.now();
        List<SalesDeal> deliveredDeals = salesDealRepository.findByDealerCodeAndDealStatus("", "DL");
        int count = 0;

        // Get all vehicles in stock status and check if they have a delivered deal
        List<Vehicle> stockVehicles = vehicleRepository.findAll().stream()
                .filter(v -> "AV".equals(v.getVehicleStatus()) || "HD".equals(v.getVehicleStatus()))
                .toList();

        for (Vehicle vehicle : stockVehicles) {
            Optional<SalesDeal> deal = salesDealRepository.findByVin(vehicle.getVin());
            if (deal.isPresent() && "DL".equals(deal.get().getDealStatus())) {
                vehicle.setVehicleStatus("SD");
                vehicle.setUpdatedTs(LocalDateTime.now());
                vehicleRepository.save(vehicle);
                count++;
                log.debug("BATDLY00: VIN {} marked SOLD", vehicle.getVin());
            }
        }
        return count;
    }

    /**
     * Phase 2: Expire pending deals older than 30 days.
     * Legacy: WS/NE/PA deals with DEAL_DATE <= 30 days ago -> status CA.
     */
    int expirePendingDeals() {
        LocalDate cutoffDate = LocalDate.now().minusDays(DEAL_EXPIRY_DAYS);
        List<String> pendingStatuses = List.of("WS", "NE", "PA");
        int count = 0;

        for (String status : pendingStatuses) {
            List<SalesDeal> oldDeals = salesDealRepository.findByDealerCodeAndDealStatus("", status)
                    .stream()
                    .filter(d -> d.getDealDate() != null && d.getDealDate().isBefore(cutoffDate))
                    .toList();
            // Need to iterate all dealers — use findAll filtered
        }

        // More efficient: scan all deals in pending statuses
        List<SalesDeal> allDeals = salesDealRepository.findAll().stream()
                .filter(d -> pendingStatuses.contains(d.getDealStatus()))
                .filter(d -> d.getDealDate() != null && d.getDealDate().isBefore(cutoffDate))
                .toList();

        for (SalesDeal deal : allDeals) {
            deal.setDealStatus("CA");
            deal.setUpdatedTs(LocalDateTime.now());
            salesDealRepository.save(deal);
            count++;
            log.debug("BATDLY00: Deal {} expired (was {})", deal.getDealNumber(), deal.getDealStatus());
        }
        return count;
    }

    /**
     * Phase 3: Calculate daily floor plan interest accrual.
     * Legacy formula: COMBINED_RATE = BASE_RATE + SPREAD
     *                 DAILY_RATE = COMBINED_RATE / 365
     *                 DAILY_INTEREST = BALANCE * DAILY_RATE / 100
     *                 CUMULATIVE = prior accrued + daily
     */
    int accrueFloorPlanInterest(List<String> warnings) {
        List<FloorPlanVehicle> activeVehicles = floorPlanVehicleRepository.findByFpStatus("AC");
        int count = 0;
        LocalDate today = LocalDate.now();

        for (FloorPlanVehicle fpv : activeVehicles) {
            Optional<FloorPlanLender> lenderOpt = floorPlanLenderRepository.findByLenderId(fpv.getLenderId());
            if (lenderOpt.isEmpty()) {
                warnings.add("No lender found for floor plan " + fpv.getFloorPlanId());
                continue;
            }

            FloorPlanLender lender = lenderOpt.get();

            // COMBINED_RATE = BASE_RATE + SPREAD (ported from BATDLY00 CALC-INTEREST)
            BigDecimal combinedRate = lender.getBaseRate().add(lender.getSpread());

            // DAILY_RATE = COMBINED_RATE / 365
            BigDecimal dailyRate = combinedRate.divide(BigDecimal.valueOf(365), 10, RoundingMode.HALF_UP);

            // DAILY_INTEREST = BALANCE * DAILY_RATE / 100
            BigDecimal dailyInterest = fpv.getCurrentBalance()
                    .multiply(dailyRate)
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

            // Get prior cumulative interest
            BigDecimal priorCumulative = fpv.getInterestAccrued() != null
                    ? fpv.getInterestAccrued() : BigDecimal.ZERO;
            BigDecimal newCumulative = priorCumulative.add(dailyInterest);

            // Insert interest record
            FloorPlanInterest interest = FloorPlanInterest.builder()
                    .floorPlanId(fpv.getFloorPlanId())
                    .calcDate(today)
                    .principalBal(fpv.getCurrentBalance())
                    .rateApplied(combinedRate)
                    .dailyInterest(dailyInterest)
                    .cumulativeInt(newCumulative)
                    .build();
            floorPlanInterestRepository.save(interest);

            // Update vehicle accrued interest and days
            fpv.setInterestAccrued(newCumulative);
            fpv.setDaysOnFloor((short) (fpv.getDaysOnFloor() + 1));
            fpv.setLastInterestDt(today);
            floorPlanVehicleRepository.save(fpv);

            count++;
        }
        return count;
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

    private DailySalesSummaryResponse toResponse(DailySalesSummary entity) {
        return DailySalesSummaryResponse.builder()
                .summaryDate(entity.getSummaryDate())
                .dealerCode(entity.getDealerCode())
                .modelYear(entity.getModelYear())
                .makeCode(entity.getMakeCode())
                .modelCode(entity.getModelCode())
                .unitsSold(entity.getUnitsSold())
                .totalRevenue(entity.getTotalRevenue())
                .totalGross(entity.getTotalGross())
                .frontGross(entity.getFrontGross())
                .backGross(entity.getBackGross())
                .avgSellingPrice(entity.getAvgSellingPrice())
                .avgGrossPerUnit(entity.getAvgGrossPerUnit())
                .build();
    }
}
