package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.StockPositionService;
import com.autosales.common.util.StockUpdateResult;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import com.autosales.modules.admin.repository.PriceMasterRepository;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.entity.StockAdjustment;
import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockAdjustmentRepository;
import com.autosales.modules.vehicle.repository.StockPositionRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Stock management service — inventory positions, adjustments, aging, alerts, reconciliation, and valuation.
 * Port of 8 legacy programs: STKINQ00, STKSUM00, STKADJT0, STKAGIN0, STKALRT0, STKHLD00, STKRCN00, STKVALS0.
 *
 * <p>STKINQ00 — Stock position inquiry by dealer<br>
 * STKSUM00 — Stock summary with value totals<br>
 * STKADJT0 — Stock adjustment processing (damage, write-off, reclassify, physical count, other)<br>
 * STKAGIN0 — Aging analysis with curtailment warnings<br>
 * STKALRT0 — Low-stock alerts with suggested reorder quantities<br>
 * STKHLD00 — Vehicle hold and release operations<br>
 * STKRCN00 — Stock reconciliation (system vs. actual counts)<br>
 * STKVALS0 — Stock valuation by category with holding cost accrual</p>
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class StockManagementService {

    private final StockPositionRepository stockPositionRepository;
    private final StockAdjustmentRepository stockAdjustmentRepository;
    private final VehicleRepository vehicleRepository;
    private final StockPositionService stockPositionService;
    private final PriceMasterRepository priceMasterRepository;
    private final ModelMasterRepository modelMasterRepository;
    private final DealerRepository dealerRepository;

    /** Valid adjustment types — maps code to display name. */
    private static final Map<String, String> ADJUST_TYPE_NAMES = Map.of(
            "DM", "Damage",
            "WO", "Write-Off",
            "RC", "Reclassify",
            "PH", "Physical Count",
            "OT", "Other"
    );

    /** Daily holding-cost rate applied to invoice price (6% annual / 365). */
    private static final BigDecimal DAILY_HOLDING_RATE = new BigDecimal("0.000164");

    /** Status codes considered "in stock" for reconciliation and valuation. */
    private static final List<String> IN_STOCK_STATUSES = List.of("AV", "HD", "AL");

    /** Statuses included in valuation (includes damaged). */
    private static final List<String> VALUATION_STATUSES = List.of("AV", "DM", "HD", "AL");

    /** Days-in-stock threshold for curtailment warning (floor-plan lender risk). */
    private static final int CURTAILMENT_DAYS = 75;

    /** Safety-stock buffer added to deficit when calculating suggested order quantity. */
    private static final int SAFETY_STOCK_BUFFER = 2;

    // ===== 1. STKINQ00 — Stock Position Inquiry =====

    /**
     * Retrieve all stock positions for a dealer, enriched with model description
     * and low-stock alert flag.
     *
     * @param dealerCode the dealer to query
     * @return list of stock position DTOs
     */
    public List<StockPositionResponse> getPositions(String dealerCode) {
        log.info("STKINQ00: Stock position inquiry for dealer={}", dealerCode);

        List<StockPosition> positions = stockPositionRepository.findByDealerCode(dealerCode);

        return positions.stream().map(pos -> {
            String modelDesc = lookupModelDesc(pos.getModelYear(), pos.getMakeCode(), pos.getModelCode());
            boolean lowStock = pos.getOnHandCount() < pos.getReorderPoint();

            return StockPositionResponse.builder()
                    .dealerCode(pos.getDealerCode())
                    .modelYear(pos.getModelYear())
                    .makeCode(pos.getMakeCode())
                    .modelCode(pos.getModelCode())
                    .modelDesc(modelDesc)
                    .onHandCount(pos.getOnHandCount())
                    .inTransitCount(pos.getInTransitCount())
                    .allocatedCount(pos.getAllocatedCount())
                    .onHoldCount(pos.getOnHoldCount())
                    .soldMtd(pos.getSoldMtd())
                    .soldYtd(pos.getSoldYtd())
                    .reorderPoint(pos.getReorderPoint())
                    .lowStockAlert(lowStock)
                    .build();
        }).collect(Collectors.toList());
    }

    // ===== 2. STKSUM00 — Stock Summary =====

    /**
     * Aggregate stock summary for a dealer: totals across all positions,
     * total inventory value, and average days in stock.
     *
     * @param dealerCode the dealer to query
     * @return stock summary DTO
     */
    public StockSummaryResponse getSummary(String dealerCode) {
        log.info("STKSUM00: Stock summary for dealer={}", dealerCode);

        Dealer dealer = dealerRepository.findById(dealerCode)
                .orElseThrow(() -> new EntityNotFoundException("Dealer", dealerCode));

        List<StockPosition> positions = stockPositionRepository.findByDealerCode(dealerCode);

        int totalOnHand = 0;
        int totalInTransit = 0;
        int totalAllocated = 0;
        int totalOnHold = 0;
        int totalSoldMtd = 0;
        int totalSoldYtd = 0;
        BigDecimal totalValue = BigDecimal.ZERO;

        for (StockPosition pos : positions) {
            totalOnHand += pos.getOnHandCount();
            totalInTransit += pos.getInTransitCount();
            totalAllocated += pos.getAllocatedCount();
            totalOnHold += pos.getOnHoldCount();
            totalSoldMtd += pos.getSoldMtd();
            totalSoldYtd += pos.getSoldYtd();

            // Join with PriceMaster for invoice price * on-hand count
            BigDecimal invoicePrice = lookupInvoicePrice(pos.getModelYear(), pos.getMakeCode(), pos.getModelCode());
            totalValue = totalValue.add(invoicePrice.multiply(BigDecimal.valueOf(pos.getOnHandCount())));
        }

        // Average days in stock from actual vehicles
        List<Vehicle> stockVehicles = vehicleRepository
                .findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(dealerCode, IN_STOCK_STATUSES);
        int avgDays = stockVehicles.isEmpty() ? 0
                : (int) stockVehicles.stream().mapToInt(v -> v.getDaysInStock()).average().orElse(0);

        return StockSummaryResponse.builder()
                .dealerCode(dealerCode)
                .dealerName(dealer.getDealerName())
                .totalOnHand(totalOnHand)
                .totalInTransit(totalInTransit)
                .totalAllocated(totalAllocated)
                .totalOnHold(totalOnHold)
                .totalSoldMtd(totalSoldMtd)
                .totalSoldYtd(totalSoldYtd)
                .totalValue(totalValue)
                .avgDaysInStock(avgDays)
                .build();
    }

    // ===== 3. STKADJT0 — Stock Adjustment =====

    /**
     * Create a stock adjustment record. Validates adjustment type, updates vehicle
     * status when applicable, and decrements on-hand for damage/write-off.
     *
     * <p>Adjustment type mapping:<br>
     * DM (Damage) — vehicle stays as-is with damage note, on-hand decremented<br>
     * WO (Write-Off) — vehicle status → WO, on-hand decremented<br>
     * RC (Reclassify) — vehicle status → AV<br>
     * PH (Physical Count) — no status change<br>
     * OT (Other) — no status change</p>
     *
     * @param request the adjustment details
     * @return adjustment response DTO
     */
    @Transactional
    public StockAdjustmentResponse createAdjustment(StockAdjustmentRequest request) {
        log.info("STKADJT0: Stock adjustment type={} vin={} dealer={}",
                request.getAdjustType(), request.getVin(), request.getDealerCode());

        // Validate adjustment type
        String adjustType = request.getAdjustType();
        if (!ADJUST_TYPE_NAMES.containsKey(adjustType)) {
            throw new BusinessValidationException(
                    "Invalid adjustment type: " + adjustType + ". Valid types: DM, WO, RC, PH, OT");
        }

        // Fetch vehicle
        Vehicle vehicle = vehicleRepository.findById(request.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", request.getVin()));

        String oldStatus = vehicle.getVehicleStatus();
        String newStatus = oldStatus; // default: no change

        switch (adjustType) {
            case "DM":
                // Damage — vehicle stays as-is but flag damage; decrement on-hand
                vehicle.setDamageFlag("Y");
                vehicle.setDamageDesc(request.getAdjustReason());
                vehicle.setUpdatedTs(LocalDateTime.now());
                vehicleRepository.save(vehicle);
                stockPositionService.processSold(request.getVin(), request.getDealerCode(),
                        request.getAdjustedBy(), "Damage adjustment: " + request.getAdjustReason());
                newStatus = oldStatus; // status unchanged for damage
                break;

            case "WO":
                // Write-Off — set status to WO; decrement on-hand
                newStatus = "WO";
                vehicle.setVehicleStatus(newStatus);
                vehicle.setUpdatedTs(LocalDateTime.now());
                vehicleRepository.save(vehicle);
                stockPositionService.processSold(request.getVin(), request.getDealerCode(),
                        request.getAdjustedBy(), "Write-off: " + request.getAdjustReason());
                break;

            case "RC":
                // Reclassify — set status to AV
                newStatus = "AV";
                vehicle.setVehicleStatus(newStatus);
                vehicle.setUpdatedTs(LocalDateTime.now());
                vehicleRepository.save(vehicle);
                break;

            case "PH":
            case "OT":
                // Physical Count / Other — no vehicle status change
                break;

            default:
                break;
        }

        // Create adjustment record
        StockAdjustment adjustment = StockAdjustment.builder()
                .dealerCode(request.getDealerCode())
                .vin(request.getVin())
                .adjustType(adjustType)
                .adjustReason(request.getAdjustReason())
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .adjustedBy(request.getAdjustedBy())
                .adjustedTs(LocalDateTime.now())
                .build();
        adjustment = stockAdjustmentRepository.save(adjustment);

        String vehicleDesc = vehicle.getModelYear() + " " + vehicle.getMakeCode() + " " + vehicle.getModelCode();

        return StockAdjustmentResponse.builder()
                .adjustId(adjustment.getAdjustId())
                .dealerCode(adjustment.getDealerCode())
                .vin(adjustment.getVin())
                .vehicleDesc(vehicleDesc)
                .adjustType(adjustType)
                .adjustTypeName(ADJUST_TYPE_NAMES.get(adjustType))
                .adjustReason(adjustment.getAdjustReason())
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .adjustedBy(adjustment.getAdjustedBy())
                .adjustedTs(adjustment.getAdjustedTs())
                .build();
    }

    // ===== 4. Paginated Adjustment List =====

    /**
     * List stock adjustments for a dealer with pagination.
     *
     * @param dealerCode the dealer code
     * @param page       zero-based page number
     * @param size       page size
     * @return paginated adjustment response
     */
    public PaginatedResponse<StockAdjustmentResponse> listAdjustments(String dealerCode, int page, int size) {
        log.info("STKADJT0: List adjustments for dealer={}, page={}, size={}", dealerCode, page, size);

        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100), Sort.by(Sort.Direction.DESC, "adjustedTs"));
        Page<StockAdjustment> adjustmentPage = stockAdjustmentRepository.findByDealerCode(dealerCode, pageRequest);

        List<StockAdjustmentResponse> content = adjustmentPage.getContent().stream().map(adj -> {
            String vehicleDesc = vehicleRepository.findById(adj.getVin())
                    .map(v -> v.getModelYear() + " " + v.getMakeCode() + " " + v.getModelCode())
                    .orElse(adj.getVin());

            return StockAdjustmentResponse.builder()
                    .adjustId(adj.getAdjustId())
                    .dealerCode(adj.getDealerCode())
                    .vin(adj.getVin())
                    .vehicleDesc(vehicleDesc)
                    .adjustType(adj.getAdjustType())
                    .adjustTypeName(ADJUST_TYPE_NAMES.getOrDefault(adj.getAdjustType(), adj.getAdjustType()))
                    .adjustReason(adj.getAdjustReason())
                    .oldStatus(adj.getOldStatus())
                    .newStatus(adj.getNewStatus())
                    .adjustedBy(adj.getAdjustedBy())
                    .adjustedTs(adj.getAdjustedTs())
                    .build();
        }).collect(Collectors.toList());

        return new PaginatedResponse<>(
                "success", null, content,
                adjustmentPage.getNumber(),
                adjustmentPage.getTotalPages(),
                adjustmentPage.getTotalElements(),
                LocalDateTime.now()
        );
    }

    // ===== 5. STKAGIN0 — Aging Analysis =====

    /**
     * Aging analysis from stock perspective. Groups vehicles into 5 age buckets
     * (0-30, 31-60, 61-90, 91-120, 120+), updates daysInStock on each vehicle,
     * and flags curtailment warnings at 75+ days.
     *
     * @param dealerCode the dealer to analyze
     * @return aging report DTO
     */
    @Transactional
    public AgingReportResponse getAgingAnalysis(String dealerCode) {
        log.info("STKAGIN0: Aging analysis for dealer={}", dealerCode);

        List<Vehicle> vehicles = vehicleRepository
                .findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(dealerCode, IN_STOCK_STATUSES);

        LocalDate today = LocalDate.now();
        BigDecimal totalValue = BigDecimal.ZERO;
        int totalDays = 0;

        // Define aging buckets
        int[] bucketCounts = new int[5];
        BigDecimal[] bucketValues = new BigDecimal[5];
        long[] bucketDayTotals = new long[5];
        String[] bucketRanges = {"0-30", "31-60", "61-90", "91-120", "120+"};
        for (int i = 0; i < 5; i++) {
            bucketValues[i] = BigDecimal.ZERO;
        }

        List<VehicleListResponse> agedVehicles = new ArrayList<>();

        for (Vehicle v : vehicles) {
            // Update days in stock from receive date
            long days = ChronoUnit.DAYS.between(v.getReceiveDate(), today);
            v.setDaysInStock((short) Math.min(days, Short.MAX_VALUE));
            vehicleRepository.save(v);

            BigDecimal invoicePrice = lookupInvoicePrice(v.getModelYear(), v.getMakeCode(), v.getModelCode());
            totalValue = totalValue.add(invoicePrice);
            totalDays += (int) days;

            // Determine bucket
            int bucket;
            if (days <= 30) bucket = 0;
            else if (days <= 60) bucket = 1;
            else if (days <= 90) bucket = 2;
            else if (days <= 120) bucket = 3;
            else bucket = 4;

            bucketCounts[bucket]++;
            bucketValues[bucket] = bucketValues[bucket].add(invoicePrice);
            bucketDayTotals[bucket] += days;

            // Flag curtailment warning vehicles (75+ days)
            if (days >= CURTAILMENT_DAYS) {
                String statusName = mapStatusName(v.getVehicleStatus());
                String vehicleDesc = v.getModelYear() + " " + v.getMakeCode() + " " + v.getModelCode();
                agedVehicles.add(VehicleListResponse.builder()
                        .vin(v.getVin())
                        .stockNumber(v.getStockNumber())
                        .vehicleDesc(vehicleDesc)
                        .vehicleStatus(v.getVehicleStatus())
                        .statusName(statusName)
                        .exteriorColor(v.getExteriorColor())
                        .daysInStock(v.getDaysInStock())
                        .dealerCode(v.getDealerCode())
                        .lotLocation(v.getLotLocation())
                        .pdiComplete(v.getPdiComplete())
                        .damageFlag(v.getDamageFlag())
                        .build());
            }
        }

        int totalVehicles = vehicles.size();
        int avgDays = totalVehicles > 0 ? totalDays / totalVehicles : 0;

        // Build bucket DTOs
        List<AgingReportResponse.AgingBucket> buckets = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            BigDecimal pct = totalVehicles > 0
                    ? BigDecimal.valueOf(bucketCounts[i] * 100.0 / totalVehicles).setScale(1, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            int bucketAvgDays = bucketCounts[i] > 0 ? (int) (bucketDayTotals[i] / bucketCounts[i]) : 0;

            buckets.add(AgingReportResponse.AgingBucket.builder()
                    .range(bucketRanges[i])
                    .count(bucketCounts[i])
                    .value(bucketValues[i])
                    .avgDays(bucketAvgDays)
                    .pctOfTotal(pct)
                    .build());
        }

        return AgingReportResponse.builder()
                .dealerCode(dealerCode)
                .totalVehicles(totalVehicles)
                .totalValue(totalValue)
                .avgDaysInStock(avgDays)
                .buckets(buckets)
                .agedVehicles(agedVehicles)
                .build();
    }

    // ===== 6. STKALRT0 — Low-Stock Alerts =====

    /**
     * Find all stock positions where on-hand count falls below reorder point.
     * Calculates deficit and suggested order quantity (deficit + safety stock buffer).
     *
     * @param dealerCode the dealer to check
     * @return list of alert DTOs
     */
    public List<StockAlertResponse> getAlerts(String dealerCode) {
        log.info("STKALRT0: Stock alerts for dealer={}", dealerCode);

        List<StockPosition> positions = stockPositionRepository.findByDealerCode(dealerCode);

        return positions.stream()
                .filter(pos -> pos.getOnHandCount() < pos.getReorderPoint())
                .map(pos -> {
                    int deficit = pos.getReorderPoint() - pos.getOnHandCount();
                    int suggestedOrder = deficit + SAFETY_STOCK_BUFFER;
                    String modelDesc = lookupModelDesc(pos.getModelYear(), pos.getMakeCode(), pos.getModelCode());

                    return StockAlertResponse.builder()
                            .alertType("LOW_STOCK")
                            .dealerCode(pos.getDealerCode())
                            .modelYear(pos.getModelYear())
                            .makeCode(pos.getMakeCode())
                            .modelCode(pos.getModelCode())
                            .modelDesc(modelDesc)
                            .currentCount(pos.getOnHandCount())
                            .reorderPoint(pos.getReorderPoint())
                            .deficit(deficit)
                            .suggestedOrder(suggestedOrder)
                            .build();
                })
                .collect(Collectors.toList());
    }

    // ===== 7. STKHLD00 HOLD — Vehicle Hold =====

    /**
     * Place a vehicle on hold. Vehicle must currently be in AV (Available) status.
     * Delegates to {@link StockPositionService#processHold}.
     *
     * @param vin     the VIN to hold
     * @param request hold reason and user
     * @return stock update result
     */
    @Transactional
    public StockUpdateResult holdVehicle(String vin, StockHoldRequest request) {
        log.info("STKHLD00 HOLD: vin={}, holdBy={}", vin, request.getHoldBy());

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        if (!"AV".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle must be in Available (AV) status to hold. Current status: " + vehicle.getVehicleStatus());
        }

        return stockPositionService.processHold(vin, vehicle.getDealerCode(),
                request.getHoldBy(), request.getReason());
    }

    // ===== 8. STKHLD00 RLSE — Vehicle Release =====

    /**
     * Release a vehicle from hold back to available. Vehicle must currently be in HD (Hold) status.
     * Delegates to {@link StockPositionService#processRelease}.
     *
     * @param vin     the VIN to release
     * @param request release reason and user
     * @return stock update result
     */
    @Transactional
    public StockUpdateResult releaseVehicle(String vin, StockReleaseRequest request) {
        log.info("STKHLD00 RLSE: vin={}, releaseBy={}", vin, request.getReleaseBy());

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        if (!"HD".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle must be in Hold (HD) status to release. Current status: " + vehicle.getVehicleStatus());
        }

        return stockPositionService.processRelease(vin, vehicle.getDealerCode(),
                request.getReleaseBy(), request.getReason());
    }

    // ===== 9. STKRCN00 — Stock Reconciliation =====

    /**
     * Reconcile system stock position counts against actual vehicle records.
     * For each position, counts vehicles with matching dealer/year/make/model
     * and status in (AV, HD, AL), then compares to the sum of onHand + onHold + allocated.
     *
     * @param dealerCode the dealer to reconcile
     * @return reconciliation response with discrepancies
     */
    public ReconciliationResponse reconcile(String dealerCode) {
        log.info("STKRCN00: Stock reconciliation for dealer={}", dealerCode);

        List<StockPosition> positions = stockPositionRepository.findByDealerCode(dealerCode);
        List<ReconciliationResponse.Discrepancy> discrepancies = new ArrayList<>();
        int totalVariance = 0;

        for (StockPosition pos : positions) {
            // System count from stock position record
            int systemCount = pos.getOnHandCount() + pos.getOnHoldCount() + pos.getAllocatedCount();

            // Actual count from vehicle records
            List<Vehicle> actualVehicles = vehicleRepository
                    .findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(dealerCode, IN_STOCK_STATUSES);
            long actualCount = actualVehicles.stream()
                    .filter(v -> Objects.equals(v.getModelYear(), pos.getModelYear())
                            && Objects.equals(v.getMakeCode(), pos.getMakeCode())
                            && Objects.equals(v.getModelCode(), pos.getModelCode()))
                    .count();

            int variance = (int) actualCount - systemCount;
            if (variance != 0) {
                String modelDesc = lookupModelDesc(pos.getModelYear(), pos.getMakeCode(), pos.getModelCode());
                discrepancies.add(ReconciliationResponse.Discrepancy.builder()
                        .modelYear(pos.getModelYear())
                        .makeCode(pos.getMakeCode())
                        .modelCode(pos.getModelCode())
                        .modelDesc(modelDesc)
                        .systemCount(systemCount)
                        .actualCount((int) actualCount)
                        .variance(variance)
                        .build());
                totalVariance += Math.abs(variance);
            }
        }

        return ReconciliationResponse.builder()
                .dealerCode(dealerCode)
                .reconciliationDate(LocalDate.now())
                .totalModels(positions.size())
                .discrepancies(discrepancies)
                .totalVariance(totalVariance)
                .reconciled(discrepancies.isEmpty())
                .build();
    }

    // ===== 10. STKVALS0 — Stock Valuation =====

    /**
     * Calculate stock valuation grouped by vehicle status category.
     * Includes invoice totals, MSRP totals, average days in stock, and accrued holding cost.
     *
     * <p>Category mapping: AV→New, HD→On Hold, AL→Allocated, other (DM)→Damaged.</p>
     *
     * @param dealerCode the dealer to value
     * @return valuation response with category breakdowns
     */
    public StockValuationResponse getValuation(String dealerCode) {
        log.info("STKVALS0: Stock valuation for dealer={}", dealerCode);

        List<Vehicle> vehicles = vehicleRepository
                .findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(dealerCode, VALUATION_STATUSES);

        // Group vehicles by status
        Map<String, List<Vehicle>> grouped = vehicles.stream()
                .collect(Collectors.groupingBy(Vehicle::getVehicleStatus));

        BigDecimal grandTotal = BigDecimal.ZERO;
        BigDecimal totalAccruedInterest = BigDecimal.ZERO;
        List<StockValuationResponse.ValuationCategory> categories = new ArrayList<>();

        for (Map.Entry<String, List<Vehicle>> entry : grouped.entrySet()) {
            String statusCode = entry.getKey();
            List<Vehicle> group = entry.getValue();

            String categoryName = mapCategoryName(statusCode);
            BigDecimal totalInvoice = BigDecimal.ZERO;
            BigDecimal totalMsrp = BigDecimal.ZERO;
            BigDecimal holdingCost = BigDecimal.ZERO;
            int totalDays = 0;

            for (Vehicle v : group) {
                BigDecimal invoicePrice = lookupInvoicePrice(v.getModelYear(), v.getMakeCode(), v.getModelCode());
                BigDecimal msrpPrice = lookupMsrpPrice(v.getModelYear(), v.getMakeCode(), v.getModelCode());

                totalInvoice = totalInvoice.add(invoicePrice);
                totalMsrp = totalMsrp.add(msrpPrice);
                totalDays += v.getDaysInStock();

                // holdingCost = invoicePrice * 0.000164 * daysInStock
                BigDecimal vehicleHolding = invoicePrice
                        .multiply(DAILY_HOLDING_RATE)
                        .multiply(BigDecimal.valueOf(v.getDaysInStock()))
                        .setScale(2, RoundingMode.HALF_UP);
                holdingCost = holdingCost.add(vehicleHolding);
            }

            int avgDays = group.isEmpty() ? 0 : totalDays / group.size();
            grandTotal = grandTotal.add(totalInvoice);
            totalAccruedInterest = totalAccruedInterest.add(holdingCost);

            categories.add(StockValuationResponse.ValuationCategory.builder()
                    .category(statusCode)
                    .categoryName(categoryName)
                    .count(group.size())
                    .totalInvoice(totalInvoice)
                    .totalMsrp(totalMsrp)
                    .avgDaysInStock(avgDays)
                    .holdingCost(holdingCost)
                    .build());
        }

        return StockValuationResponse.builder()
                .dealerCode(dealerCode)
                .categories(categories)
                .grandTotal(grandTotal)
                .totalAccruedInterest(totalAccruedInterest)
                .build();
    }

    // ===== Private Helpers =====

    /**
     * Look up model description from ModelMaster.
     */
    private String lookupModelDesc(Short modelYear, String makeCode, String modelCode) {
        return modelMasterRepository.findById(new ModelMasterId(modelYear, makeCode, modelCode))
                .map(m -> m.getModelYear() + " " + m.getMakeCode() + " " + m.getModelName())
                .orElse(modelYear + " " + makeCode + " " + modelCode);
    }

    /**
     * Look up current effective invoice price from PriceMaster.
     */
    private BigDecimal lookupInvoicePrice(Short modelYear, String makeCode, String modelCode) {
        return priceMasterRepository.findCurrentEffective(modelYear, makeCode, modelCode, LocalDate.now())
                .map(PriceMaster::getInvoicePrice)
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Look up current effective MSRP from PriceMaster.
     */
    private BigDecimal lookupMsrpPrice(Short modelYear, String makeCode, String modelCode) {
        return priceMasterRepository.findCurrentEffective(modelYear, makeCode, modelCode, LocalDate.now())
                .map(PriceMaster::getMsrp)
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Map vehicle status code to category display name for valuation.
     */
    private String mapCategoryName(String statusCode) {
        return switch (statusCode) {
            case "AV" -> "New";
            case "HD" -> "On Hold";
            case "AL" -> "Allocated";
            case "DM" -> "Damaged";
            default -> statusCode;
        };
    }

    /**
     * Map vehicle status code to human-readable name.
     */
    private String mapStatusName(String statusCode) {
        return switch (statusCode) {
            case "AV" -> "Available";
            case "HD" -> "On Hold";
            case "AL" -> "Allocated";
            case "IT" -> "In Transit";
            case "SD" -> "Sold";
            case "TR" -> "Transfer";
            case "WO" -> "Written Off";
            case "DM" -> "Damaged";
            default -> statusCode;
        };
    }
}
