package com.autosales.modules.vehicle.service;

import com.autosales.common.util.PaginatedResponse;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.repository.PriceMasterRepository;
import com.autosales.modules.vehicle.dto.SnapshotCaptureRequest;
import com.autosales.modules.vehicle.dto.SnapshotResponse;
import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.StockSnapshot;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockPositionRepository;
import com.autosales.modules.vehicle.repository.StockSnapshotRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Service for daily stock snapshot capture and historical reporting.
 * Port of STKSNAP0.cbl — end-of-day stock position snapshot batch program.
 *
 * <p>Captures a point-in-time snapshot of stock positions per dealer/model combination,
 * including computed average days-in-stock and total inventory value.</p>
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class StockSnapshotService {

    private final StockSnapshotRepository stockSnapshotRepository;
    private final StockPositionRepository stockPositionRepository;
    private final VehicleRepository vehicleRepository;
    private final PriceMasterRepository priceMasterRepository;

    /**
     * Capture a stock snapshot for a specific dealer or all dealers.
     * Deletes any existing snapshot for the given date/dealer before inserting.
     *
     * @param request optional dealerCode (null = all dealers) and snapshotDate (null = today)
     * @return the count of snapshot records created
     */
    @Transactional
    public int captureSnapshot(SnapshotCaptureRequest request) {
        LocalDate snapshotDate = request.getSnapshotDate() != null ? request.getSnapshotDate() : LocalDate.now();
        String dealerCode = request.getDealerCode();

        log.info("SNAPSHOT CAPTURE: dealer={}, date={}", dealerCode != null ? dealerCode : "ALL", snapshotDate);

        // Fetch stock positions to snapshot
        List<StockPosition> positions;
        if (dealerCode != null && !dealerCode.isBlank()) {
            // Delete existing snapshots for this dealer/date
            stockSnapshotRepository.deleteByDealerCodeAndSnapshotDate(dealerCode, snapshotDate);
            positions = stockPositionRepository.findByDealerCode(dealerCode);
        } else {
            // Delete all snapshots for this date, then snapshot all positions
            stockSnapshotRepository.deleteBySnapshotDate(snapshotDate);
            positions = stockPositionRepository.findAll();
        }

        int count = 0;
        for (StockPosition pos : positions) {
            // Compute average days in stock from actual vehicle records
            short avgDays = computeAvgDaysInStock(pos.getDealerCode(), pos.getModelYear(),
                    pos.getMakeCode(), pos.getModelCode());

            // Compute total value: onHandCount * invoicePrice from PriceMaster
            BigDecimal totalValue = computeTotalValue(pos.getModelYear(), pos.getMakeCode(),
                    pos.getModelCode(), pos.getOnHandCount());

            StockSnapshot snapshot = StockSnapshot.builder()
                    .snapshotDate(snapshotDate)
                    .dealerCode(pos.getDealerCode())
                    .modelYear(pos.getModelYear())
                    .makeCode(pos.getMakeCode())
                    .modelCode(pos.getModelCode())
                    .onHandCount(pos.getOnHandCount())
                    .inTransitCount(pos.getInTransitCount())
                    .onHoldCount(pos.getOnHoldCount())
                    .totalValue(totalValue)
                    .avgDaysInStock(avgDays)
                    .build();

            stockSnapshotRepository.save(snapshot);
            count++;
        }

        log.info("SNAPSHOT CAPTURE COMPLETE: {} records created for date={}", count, snapshotDate);
        return count;
    }

    /**
     * Retrieve paginated historical snapshots for a dealer within a date range.
     */
    public PaginatedResponse<SnapshotResponse> getSnapshots(String dealerCode, LocalDate from, LocalDate to,
                                                             int page, int size) {
        log.debug("Listing snapshots for dealer={}, from={}, to={}, page={}, size={}",
                dealerCode, from, to, page, size);

        // Default date range: last 30 days
        LocalDate effectiveFrom = from != null ? from : LocalDate.now().minusDays(30);
        LocalDate effectiveTo = to != null ? to : LocalDate.now();

        Page<StockSnapshot> snapshots = stockSnapshotRepository.findByDealerCodeAndSnapshotDateBetween(
                dealerCode, effectiveFrom, effectiveTo,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "snapshotDate")));

        var content = snapshots.getContent().stream()
                .map(this::toResponse)
                .toList();

        return new PaginatedResponse<>("success", null, content,
                snapshots.getNumber(), snapshots.getTotalPages(), snapshots.getTotalElements(),
                LocalDateTime.now());
    }

    // ── Private helpers ──────────────────────────────────────────────────

    private short computeAvgDaysInStock(String dealerCode, Short modelYear, String makeCode, String modelCode) {
        List<Vehicle> vehicles = vehicleRepository.findByDealerCodeAndVehicleStatus(dealerCode, "AV");

        // Filter to matching model
        List<Vehicle> matching = vehicles.stream()
                .filter(v -> modelYear.equals(v.getModelYear())
                        && makeCode.equals(v.getMakeCode())
                        && modelCode.equals(v.getModelCode()))
                .toList();

        if (matching.isEmpty()) {
            return 0;
        }

        long totalDays = matching.stream()
                .mapToLong(v -> {
                    if (v.getReceiveDate() != null) {
                        return ChronoUnit.DAYS.between(v.getReceiveDate(), LocalDate.now());
                    }
                    return v.getDaysInStock();
                })
                .sum();

        return (short) (totalDays / matching.size());
    }

    private BigDecimal computeTotalValue(Short modelYear, String makeCode, String modelCode, short onHandCount) {
        if (onHandCount <= 0) {
            return BigDecimal.ZERO;
        }

        return priceMasterRepository.findCurrentEffective(modelYear, makeCode, modelCode, LocalDate.now())
                .map(PriceMaster::getInvoicePrice)
                .map(price -> price.multiply(BigDecimal.valueOf(onHandCount)))
                .orElse(BigDecimal.ZERO);
    }

    private SnapshotResponse toResponse(StockSnapshot snapshot) {
        String modelDesc = snapshot.getModelYear() + " " + snapshot.getMakeCode() + " " + snapshot.getModelCode();
        return SnapshotResponse.builder()
                .snapshotDate(snapshot.getSnapshotDate())
                .dealerCode(snapshot.getDealerCode())
                .modelYear(snapshot.getModelYear())
                .makeCode(snapshot.getMakeCode())
                .modelCode(snapshot.getModelCode())
                .modelDesc(modelDesc)
                .onHandCount(snapshot.getOnHandCount())
                .inTransitCount(snapshot.getInTransitCount())
                .onHoldCount(snapshot.getOnHoldCount())
                .avgDaysInStock(snapshot.getAvgDaysInStock())
                .totalValue(snapshot.getTotalValue())
                .build();
    }
}
