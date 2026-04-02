package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.MonthlySnapshotResponse;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.entity.MonthlySnapshot;
import com.autosales.modules.batch.entity.MonthlySnapshotId;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.batch.repository.MonthlySnapshotRepository;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.finance.repository.FinanceProductRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockPositionRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Monthly close processing service.
 * Port of BATMTH00.cbl — three-phase monthly batch:
 * Phase 1: Calculate dealer month-end statistics → MONTHLY_SNAPSHOT
 * Phase 2: Roll monthly counters (reset SOLD_MTD on STOCK_POSITION)
 * Phase 3: Archive completed deals older than 18 months
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class MonthlyBatchService {

    private static final String PROGRAM_ID = "BATMTH00";
    private static final int ARCHIVE_MONTHS = 18;

    private final MonthlySnapshotRepository monthlySnapshotRepository;
    private final BatchControlRepository batchControlRepository;
    private final DealerRepository dealerRepository;
    private final SalesDealRepository salesDealRepository;
    private final VehicleRepository vehicleRepository;
    private final StockPositionRepository stockPositionRepository;
    private final FinanceProductRepository financeProductRepository;

    // ── Query Methods (read-only) ─────────────────────────────────────

    public List<MonthlySnapshotResponse> getSnapshotsByDealer(String dealerCode) {
        return monthlySnapshotRepository.findByDealerCodeOrderBySnapshotMonthDesc(dealerCode)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<MonthlySnapshotResponse> getSnapshotsByMonth(String snapshotMonth) {
        return monthlySnapshotRepository.findBySnapshotMonth(snapshotMonth)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<MonthlySnapshotResponse> getSnapshotRange(String dealerCode,
                                                           String startMonth,
                                                           String endMonth) {
        return monthlySnapshotRepository
                .findByDealerCodeAndSnapshotMonthBetweenOrderBySnapshotMonthDesc(
                        dealerCode, startMonth, endMonth)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ── BATMTH00: Run Monthly Close ───────────────────────────────────

    @Transactional
    public BatchRunResult runMonthlyClose() {
        log.info("BATMTH00: Starting monthly close processing");
        LocalDateTime startedAt = LocalDateTime.now();
        List<String> phases = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        int totalProcessed = 0;

        String currentMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));

        // Phase 1 — Calculate dealer month-end snapshots
        int phase1Count = calculateMonthlySnapshots(currentMonth, warnings);
        phases.add("Phase 1: Monthly snapshots calculated — " + phase1Count + " dealers");
        totalProcessed += phase1Count;

        // Phase 2 — Roll monthly counters (reset SOLD_MTD)
        int phase2Count = rollMonthlyCounters();
        phases.add("Phase 2: Stock position counters rolled — " + phase2Count);
        totalProcessed += phase2Count;

        // Phase 3 — Archive old completed deals
        int phase3Count = archiveOldDeals();
        phases.add("Phase 3: Deals archived — " + phase3Count);
        totalProcessed += phase3Count;

        updateBatchControl(totalProcessed);

        log.info("BATMTH00: Completed — {} records processed", totalProcessed);
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
     * Phase 1: For each active dealer, calculate monthly KPIs.
     * Ported from BATMTH00 CALC-MONTHLY-STATS.
     * KPIs: units sold, revenue, gross, F&I gross, avg days to sell, F&I per deal.
     */
    int calculateMonthlySnapshots(String currentMonth, List<String> warnings) {
        List<Dealer> activeDealers = dealerRepository.findByActiveFlagOrderByDealerName("Y");
        int count = 0;
        LocalDate monthStart = LocalDate.now().withDayOfMonth(1);
        LocalDate monthEnd = LocalDate.now();

        for (Dealer dealer : activeDealers) {
            String dc = dealer.getDealerCode();

            // Get delivered deals this month
            List<SalesDeal> monthDeals = salesDealRepository
                    .findByDealerCodeAndDealDateBetween(dc, monthStart, monthEnd)
                    .stream()
                    .filter(d -> "DL".equals(d.getDealStatus()) || "SD".equals(d.getDealStatus()))
                    .toList();

            short unitsSold = (short) monthDeals.size();
            if (unitsSold == 0) {
                continue; // Skip dealers with no sales this month
            }

            BigDecimal totalRevenue = monthDeals.stream()
                    .map(SalesDeal::getTotalPrice)
                    .filter(p -> p != null)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal totalGross = monthDeals.stream()
                    .map(SalesDeal::getTotalGross)
                    .filter(g -> g != null)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            // F&I gross — sum grossProfit from finance_product for these deals
            BigDecimal fiGross = BigDecimal.ZERO;
            for (SalesDeal deal : monthDeals) {
                BigDecimal dealFi = financeProductRepository.findByDealNumber(deal.getDealNumber())
                        .stream()
                        .map(fp -> fp.getGrossProfit())
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                fiGross = fiGross.add(dealFi);
            }

            // Average days to sell — from vehicle receive date to deal date
            long totalDays = 0;
            int daysCount = 0;
            for (SalesDeal deal : monthDeals) {
                if (deal.getVin() != null) {
                    Optional<Vehicle> vOpt = vehicleRepository.findById(deal.getVin());
                    if (vOpt.isPresent() && vOpt.get().getReceiveDate() != null && deal.getDealDate() != null) {
                        totalDays += ChronoUnit.DAYS.between(vOpt.get().getReceiveDate(), deal.getDealDate());
                        daysCount++;
                    }
                }
            }
            short avgDaysToSell = daysCount > 0 ? (short) (totalDays / daysCount) : 0;

            // F&I per deal = F&I gross / units sold
            BigDecimal fiPerDeal = fiGross.divide(BigDecimal.valueOf(unitsSold), 2, RoundingMode.HALF_UP);

            // Upsert snapshot (legacy: INSERT, on -803 UPDATE)
            MonthlySnapshotId id = new MonthlySnapshotId(currentMonth, dc);
            MonthlySnapshot snapshot = monthlySnapshotRepository.findById(id)
                    .orElse(MonthlySnapshot.builder()
                            .snapshotMonth(currentMonth)
                            .dealerCode(dc)
                            .createdTs(LocalDateTime.now())
                            .build());

            snapshot.setTotalUnitsSold(unitsSold);
            snapshot.setTotalRevenue(totalRevenue);
            snapshot.setTotalGross(totalGross);
            snapshot.setTotalFiGross(fiGross);
            snapshot.setAvgDaysToSell(avgDaysToSell);
            snapshot.setInventoryTurn(BigDecimal.ZERO); // calculated separately
            snapshot.setFiPerDeal(fiPerDeal);
            snapshot.setFrozenFlag("Y");
            snapshot.setCreatedTs(snapshot.getCreatedTs() != null ? snapshot.getCreatedTs() : LocalDateTime.now());
            monthlySnapshotRepository.save(snapshot);
            count++;
        }
        return count;
    }

    /**
     * Phase 2: Reset SOLD_MTD to 0 on all stock positions.
     * Ported from BATMTH00 ROLL-MONTHLY-COUNTERS.
     */
    int rollMonthlyCounters() {
        List<StockPosition> positions = stockPositionRepository.findAll();
        int count = 0;
        for (StockPosition sp : positions) {
            sp.setSoldMtd((short) 0);
            sp.setUpdatedTs(LocalDateTime.now());
            stockPositionRepository.save(sp);
            count++;
        }
        return count;
    }

    /**
     * Phase 3: Archive completed deals older than 18 months.
     * Legacy: DL/CA/UW deals with delivery_date <= 18 months ago -> status 'AR'.
     */
    int archiveOldDeals() {
        LocalDate cutoff = LocalDate.now().minusMonths(ARCHIVE_MONTHS);
        List<String> completedStatuses = List.of("DL", "CA");
        int count = 0;

        List<SalesDeal> oldDeals = salesDealRepository.findAll().stream()
                .filter(d -> completedStatuses.contains(d.getDealStatus()))
                .filter(d -> d.getDeliveryDate() != null && d.getDeliveryDate().isBefore(cutoff))
                .toList();

        for (SalesDeal deal : oldDeals) {
            deal.setDealStatus("AR");
            deal.setUpdatedTs(LocalDateTime.now());
            salesDealRepository.save(deal);
            count++;
            log.debug("BATMTH00: Deal {} archived", deal.getDealNumber());
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

    private MonthlySnapshotResponse toResponse(MonthlySnapshot entity) {
        return MonthlySnapshotResponse.builder()
                .snapshotMonth(entity.getSnapshotMonth())
                .dealerCode(entity.getDealerCode())
                .totalUnitsSold(entity.getTotalUnitsSold())
                .totalRevenue(entity.getTotalRevenue())
                .totalGross(entity.getTotalGross())
                .totalFiGross(entity.getTotalFiGross())
                .avgDaysToSell(entity.getAvgDaysToSell())
                .inventoryTurn(entity.getInventoryTurn())
                .fiPerDeal(entity.getFiPerDeal())
                .csiScore(entity.getCsiScore())
                .frozenFlag(entity.getFrozenFlag())
                .createdTs(entity.getCreatedTs())
                .build();
    }
}
