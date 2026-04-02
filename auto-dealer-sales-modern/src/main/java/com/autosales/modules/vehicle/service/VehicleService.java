package com.autosales.modules.vehicle.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.SequenceGenerator;
import com.autosales.common.util.StockPositionService;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.repository.PriceMasterRepository;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.entity.PdiSchedule;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.entity.VehicleOption;
import com.autosales.modules.vehicle.entity.VehicleStatusHist;
import com.autosales.modules.vehicle.repository.LotLocationRepository;
import com.autosales.modules.vehicle.repository.PdiScheduleRepository;
import com.autosales.modules.vehicle.repository.VehicleOptionRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import com.autosales.modules.vehicle.repository.VehicleStatusHistRepository;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Core vehicle inventory service.
 * Port of VEHINQ00.cbl (inquiry), VEHLST00.cbl (list/search),
 * VEHUPD00.cbl (update/status transition), VEHRCV00.cbl (receive into stock),
 * VEHALL00.cbl (factory allocation), VEHAGE00.cbl (aging report).
 *
 * <p>Manages vehicle lifecycle from production through allocation, transit,
 * receiving, availability, sale, and write-off. Enforces a strict status
 * transition matrix ported from the legacy COBOL validation tables.</p>
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final VehicleOptionRepository vehicleOptionRepository;
    private final VehicleStatusHistRepository vehicleStatusHistRepository;
    private final LotLocationRepository lotLocationRepository;
    private final StockPositionService stockPositionService;
    private final PriceMasterRepository priceMasterRepository;
    private final PdiScheduleRepository pdiScheduleRepository;
    private final FieldFormatter fieldFormatter;
    private final SequenceGenerator sequenceGenerator;

    // ── Status code → display name map (ported from VEHINQ00 WS-STATUS-TABLE) ──

    private static final Map<String, String> STATUS_NAMES = Map.ofEntries(
            Map.entry("PR", "Produced"),
            Map.entry("AL", "Allocated"),
            Map.entry("IT", "In Transit"),
            Map.entry("DL", "Delivered"),
            Map.entry("AV", "Available"),
            Map.entry("HD", "On Hold"),
            Map.entry("SD", "Sold"),
            Map.entry("TR", "Transfer"),
            Map.entry("SV", "Service"),
            Map.entry("WO", "Write-Off"),
            Map.entry("RJ", "Rejected")
    );

    // ── Status transition matrix (ported from VEHUPD00 WS-VALID-TRANS table) ──

    private static final Map<String, List<String>> VALID_TRANSITIONS = Map.ofEntries(
            Map.entry("PR", List.of("AL", "IT")),
            Map.entry("AL", List.of("DL", "AV", "IT")),
            Map.entry("IT", List.of("DL", "AV")),
            Map.entry("DL", List.of("AV")),
            Map.entry("AV", List.of("HD", "SD", "TR", "SV")),
            Map.entry("HD", List.of("AV")),
            Map.entry("TR", List.of("AV")),
            Map.entry("SV", List.of("AV")),
            Map.entry("SD", List.of())  // blocked — must use deal unwind
    );

    // ── Aging bucket boundaries (ported from VEHAGE00 WS-AGE-RANGES) ──

    private static final int[] AGING_BOUNDARIES = {30, 60, 90, 120};
    private static final String[] AGING_LABELS = {"0-30", "31-60", "61-90", "91-120", "120+"};
    private static final int AGED_THRESHOLD_DAYS = 90;

    // ═══════════════════════════════════════════════════════════════════
    // 1. GET VEHICLE — port of VEHINQ00
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Fetch a single vehicle with options and status history.
     * Port of VEHINQ00.cbl — vehicle inquiry with full detail display.
     *
     * @param vin the 17-character VIN
     * @return full vehicle response with options and history
     * @throws EntityNotFoundException if the VIN does not exist
     */
    public VehicleResponse getVehicle(String vin) {
        log.info("VEHINQ00: Vehicle inquiry — VIN={}", vin);

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        List<VehicleOption> options = vehicleOptionRepository.findByVin(vin);
        List<VehicleStatusHist> history = vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(vin);

        return toResponse(vehicle, options, history);
    }

    // ═══════════════════════════════════════════════════════════════════
    // 2. LIST VEHICLES — port of VEHLST00
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Search and list vehicles for a dealer with optional filters.
     * Port of VEHLST00.cbl — vehicle list/search with pagination.
     *
     * @param dealerCode the dealer code (required)
     * @param status     optional status filter
     * @param modelYear  optional model year filter
     * @param makeCode   optional make filter
     * @param modelCode  optional model filter
     * @param color      optional exterior color filter
     * @param page       zero-based page number
     * @param size       page size
     * @return paginated list of vehicles
     */
    public PaginatedResponse<VehicleListResponse> listVehicles(String dealerCode, String status,
                                                                Short modelYear, String makeCode,
                                                                String modelCode, String color,
                                                                int page, int size) {
        log.info("VEHLST00: Vehicle list — dealer={}, status={}, year={}, make={}, model={}, color={}, page={}, size={}",
                dealerCode, status, modelYear, makeCode, modelCode, color, page, size);

        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100),
                Sort.by(Sort.Direction.DESC, "daysInStock").and(Sort.by(Sort.Direction.ASC, "vin")));

        Page<Vehicle> vehiclePage = vehicleRepository.searchVehicles(
                dealerCode, status, modelYear, makeCode, modelCode, color, pageRequest);

        List<VehicleListResponse> content = vehiclePage.getContent().stream()
                .map(this::toListResponse)
                .toList();

        return new PaginatedResponse<>(
                "success",
                null,
                content,
                vehiclePage.getNumber(),
                vehiclePage.getTotalPages(),
                vehiclePage.getTotalElements(),
                LocalDateTime.now()
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    // 3. UPDATE VEHICLE — port of VEHUPD00
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Update vehicle fields and/or transition status.
     * Port of VEHUPD00.cbl — vehicle update with status transition validation.
     *
     * <p>CRITICAL: Enforces the legacy status transition matrix. The transition
     * to WO or RJ is always allowed from any status. Transition from SD is
     * blocked — the deal unwind process must be used instead.</p>
     *
     * @param vin     the VIN to update
     * @param request update request with optional status change and field updates
     * @return updated vehicle response
     * @throws EntityNotFoundException       if the VIN does not exist
     * @throws BusinessValidationException   if the status transition is invalid
     */
    @Transactional
    @Auditable(action = "UPD", entity = "VEHICLE", keyExpression = "#vin")
    public VehicleResponse updateVehicle(String vin, VehicleUpdateRequest request) {
        log.info("VEHUPD00: Vehicle update — VIN={}, newStatus={}", vin, request.getVehicleStatus());

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        String oldStatus = vehicle.getVehicleStatus();

        // --- Status transition validation ---
        if (request.getVehicleStatus() != null && !request.getVehicleStatus().equals(oldStatus)) {
            String newStatus = request.getVehicleStatus();
            validateStatusTransition(oldStatus, newStatus);

            vehicle.setVehicleStatus(newStatus);
            vehicle.setUpdatedTs(LocalDateTime.now());

            // Record status change in history
            recordStatusHistory(vin, oldStatus, newStatus, request.getReason());
        }

        // --- Update optional fields if provided ---
        if (request.getLotLocation() != null) {
            vehicle.setLotLocation(request.getLotLocation());
        }
        if (request.getOdometer() != null) {
            vehicle.setOdometer(request.getOdometer());
        }
        if (request.getDamageFlag() != null) {
            vehicle.setDamageFlag(request.getDamageFlag());
        }
        if (request.getDamageDesc() != null) {
            vehicle.setDamageDesc(request.getDamageDesc());
        }
        if (request.getKeyNumber() != null) {
            vehicle.setKeyNumber(request.getKeyNumber());
        }

        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        List<VehicleOption> options = vehicleOptionRepository.findByVin(vin);
        List<VehicleStatusHist> history = vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(vin);

        return toResponse(vehicle, options, history);
    }

    // ═══════════════════════════════════════════════════════════════════
    // 4. RECEIVE VEHICLE — port of VEHRCV00
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Receive a vehicle into dealer inventory.
     * Port of VEHRCV00.cbl — vehicle receive processing.
     *
     * <p>Vehicle must be in PR, AL, or IT status. Sets status to AV (Available),
     * assigns receive date, resets days-in-stock, auto-generates stock number
     * if not provided, creates a PDI schedule, and updates stock position counts.</p>
     *
     * @param vin     the VIN being received
     * @param request receive details (lot location, odometer, damage info, etc.)
     * @return updated vehicle response
     * @throws EntityNotFoundException       if the VIN does not exist
     * @throws BusinessValidationException   if the vehicle is not in a receivable status
     */
    @Transactional
    @Auditable(action = "UPD", entity = "VEHICLE", keyExpression = "#vin")
    public VehicleResponse receiveVehicle(String vin, VehicleReceiveRequest request) {
        log.info("VEHRCV00: Vehicle receive — VIN={}", vin);

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        String oldStatus = vehicle.getVehicleStatus();
        if (!"PR".equals(oldStatus) && !"AL".equals(oldStatus) && !"IT".equals(oldStatus)) {
            throw new BusinessValidationException(
                    "Vehicle must be in PR, AL, or IT status to receive. Current status: " + oldStatus);
        }

        // --- Update vehicle fields ---
        vehicle.setVehicleStatus("AV");
        vehicle.setReceiveDate(LocalDate.now());
        vehicle.setDaysInStock((short) 0);
        vehicle.setDealerCode(vehicle.getDealerCode());

        // Auto-generate stock number if not provided
        String stockNumber = request.getStockNumber();
        if (stockNumber == null || stockNumber.isBlank()) {
            stockNumber = sequenceGenerator.generateStockNumber();
        }
        vehicle.setStockNumber(stockNumber);

        // Set fields from request
        if (request.getLotLocation() != null) {
            vehicle.setLotLocation(request.getLotLocation());
        }
        if (request.getOdometer() != null) {
            vehicle.setOdometer(request.getOdometer());
        }
        if (request.getDamageFlag() != null) {
            vehicle.setDamageFlag(request.getDamageFlag());
        }
        if (request.getDamageDesc() != null) {
            vehicle.setDamageDesc(request.getDamageDesc());
        }
        if (request.getKeyNumber() != null) {
            vehicle.setKeyNumber(request.getKeyNumber());
        }

        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        // --- Create PDI schedule (42 checklist items, status SC = Scheduled) ---
        PdiSchedule pdi = PdiSchedule.builder()
                .vin(vin)
                .dealerCode(vehicle.getDealerCode())
                .scheduledDate(LocalDate.now().plusDays(1))
                .pdiStatus("SC")
                .checklistItems((short) 42)
                .itemsPassed((short) 0)
                .itemsFailed((short) 0)
                .notes(request.getInspectionNotes())
                .build();
        pdiScheduleRepository.save(pdi);

        // --- Update stock position counts ---
        stockPositionService.processReceive(vin, vehicle.getDealerCode(), "SYSTEM", "Vehicle received into stock");

        // --- Record status history ---
        recordStatusHistory(vin, oldStatus, "AV", "Vehicle received into dealer inventory");

        List<VehicleOption> options = vehicleOptionRepository.findByVin(vin);
        List<VehicleStatusHist> history = vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(vin);

        return toResponse(vehicle, options, history);
    }

    // ═══════════════════════════════════════════════════════════════════
    // 5. ALLOCATE VEHICLE — port of VEHALL00
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Allocate a vehicle from factory production to a dealer.
     * Port of VEHALL00.cbl — vehicle allocation processing.
     *
     * <p>Vehicle must be in PR (Produced) status. Sets status to AL (Allocated)
     * and assigns the dealer code from the request context.</p>
     *
     * @param vin     the VIN being allocated
     * @param request allocation details (deal number, customer, reason)
     * @return updated vehicle response
     * @throws EntityNotFoundException       if the VIN does not exist
     * @throws BusinessValidationException   if the vehicle is not in PR status
     */
    @Transactional
    @Auditable(action = "UPD", entity = "VEHICLE", keyExpression = "#vin")
    public VehicleResponse allocateVehicle(String vin, VehicleAllocateRequest request) {
        log.info("VEHALL00: Vehicle allocate — VIN={}, reason={}", vin, request.getReason());

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        String oldStatus = vehicle.getVehicleStatus();
        if (!"PR".equals(oldStatus)) {
            throw new BusinessValidationException(
                    "Vehicle must be in PR status to allocate. Current status: " + oldStatus);
        }

        vehicle.setVehicleStatus("AL");
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        // --- Update stock position counts ---
        stockPositionService.processAllocate(vin, vehicle.getDealerCode(), "SYSTEM",
                request.getReason() != null ? request.getReason() : "Factory allocation");

        // --- Record status history ---
        recordStatusHistory(vin, oldStatus, "AL",
                request.getReason() != null ? request.getReason() : "Factory allocation");

        List<VehicleOption> options = vehicleOptionRepository.findByVin(vin);
        List<VehicleStatusHist> history = vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(vin);

        return toResponse(vehicle, options, history);
    }

    // ═══════════════════════════════════════════════════════════════════
    // 6. AGING REPORT — port of VEHAGE00
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Generate a vehicle aging report for a dealer.
     * Port of VEHAGE00.cbl — vehicle aging analysis and inventory turn report.
     *
     * <p>Fetches vehicles in AV, HD, AL status with a receive date, computes
     * days since receive, and buckets them into aging ranges. Looks up invoice
     * price from the price master for valuation. Vehicles 90+ days are flagged
     * as aged inventory.</p>
     *
     * @param dealerCode the dealer code
     * @return aging report with buckets, totals, and aged vehicle list
     */
    public AgingReportResponse getAgingReport(String dealerCode) {
        log.info("VEHAGE00: Aging report — dealer={}", dealerCode);

        List<Vehicle> vehicles = vehicleRepository
                .findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                        dealerCode, List.of("AV", "HD", "AL"));

        LocalDate today = LocalDate.now();
        int totalVehicles = vehicles.size();

        // Initialize aging buckets
        int[] bucketCounts = new int[AGING_LABELS.length];
        BigDecimal[] bucketValues = new BigDecimal[AGING_LABELS.length];
        long[] bucketDaysTotal = new long[AGING_LABELS.length];
        for (int i = 0; i < AGING_LABELS.length; i++) {
            bucketValues[i] = BigDecimal.ZERO;
            bucketDaysTotal[i] = 0;
        }

        BigDecimal totalValue = BigDecimal.ZERO;
        long totalDays = 0;
        List<VehicleListResponse> agedVehicles = new ArrayList<>();

        for (Vehicle v : vehicles) {
            long days = ChronoUnit.DAYS.between(v.getReceiveDate(), today);

            // Look up invoice price from price master
            BigDecimal invoicePrice = lookupInvoicePrice(v);
            totalValue = totalValue.add(invoicePrice);
            totalDays += days;

            // Determine bucket index
            int bucketIdx = determineBucketIndex(days);
            bucketCounts[bucketIdx]++;
            bucketValues[bucketIdx] = bucketValues[bucketIdx].add(invoicePrice);
            bucketDaysTotal[bucketIdx] += days;

            // Flag vehicles 90+ days as aged
            if (days >= AGED_THRESHOLD_DAYS) {
                agedVehicles.add(toListResponse(v));
            }
        }

        // Build bucket response list
        List<AgingReportResponse.AgingBucket> buckets = new ArrayList<>();
        for (int i = 0; i < AGING_LABELS.length; i++) {
            int count = bucketCounts[i];
            BigDecimal pctOfTotal = totalVehicles > 0
                    ? BigDecimal.valueOf(count * 100.0 / totalVehicles).setScale(2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            int avgDays = count > 0 ? (int) (bucketDaysTotal[i] / count) : 0;

            buckets.add(AgingReportResponse.AgingBucket.builder()
                    .range(AGING_LABELS[i])
                    .count(count)
                    .value(bucketValues[i])
                    .avgDays(avgDays)
                    .pctOfTotal(pctOfTotal)
                    .build());
        }

        int avgDaysInStock = totalVehicles > 0 ? (int) (totalDays / totalVehicles) : 0;

        return AgingReportResponse.builder()
                .dealerCode(dealerCode)
                .totalVehicles(totalVehicles)
                .totalValue(totalValue)
                .avgDaysInStock(avgDaysInStock)
                .buckets(buckets)
                .agedVehicles(agedVehicles)
                .build();
    }

    // ═══════════════════════════════════════════════════════════════════
    // 7. STATUS HISTORY
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Fetch the full status history for a vehicle, newest first.
     *
     * @param vin the VIN
     * @return list of status history entries
     */
    // Read-only — no audit needed
    public List<VehicleHistoryEntry> getStatusHistory(String vin) {
        log.info("Vehicle status history — VIN={}", vin);

        List<VehicleStatusHist> history = vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(vin);
        return history.stream()
                .map(this::toHistoryEntry)
                .toList();
    }

    // ═══════════════════════════════════════════════════════════════════
    // Private helpers
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Validate that a status transition is allowed per the legacy transition matrix.
     * WO and RJ are always allowed as target statuses from any current status.
     * SD is a terminal status — deal unwind must be used instead of direct transition.
     */
    private void validateStatusTransition(String currentStatus, String newStatus) {
        // WO and RJ are always allowed
        if ("WO".equals(newStatus) || "RJ".equals(newStatus)) {
            return;
        }

        // SD is terminal — cannot transition out
        if ("SD".equals(currentStatus)) {
            throw new BusinessValidationException(
                    "Cannot change from SD (Sold) status — use deal unwind process");
        }

        List<String> validTargets = VALID_TRANSITIONS.get(currentStatus);
        if (validTargets == null || !validTargets.contains(newStatus)) {
            throw new BusinessValidationException(
                    String.format("Invalid status transition: %s (%s) -> %s (%s)",
                            currentStatus, getStatusName(currentStatus),
                            newStatus, getStatusName(newStatus)));
        }
    }

    /**
     * Record a status transition in the vehicle_status_hist table.
     */
    private void recordStatusHistory(String vin, String oldStatus, String newStatus, String reason) {
        int nextSeq = vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc(vin)
                .map(h -> h.getStatusSeq() + 1)
                .orElse(1);

        VehicleStatusHist hist = VehicleStatusHist.builder()
                .vin(vin)
                .statusSeq(nextSeq)
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .changedBy("SYSTEM")
                .changeReason(reason)
                .changedTs(LocalDateTime.now())
                .build();
        vehicleStatusHistRepository.save(hist);
    }

    /**
     * Look up invoice price from the price master for a vehicle's year/make/model.
     * Returns zero if no price record is found.
     */
    private BigDecimal lookupInvoicePrice(Vehicle vehicle) {
        Optional<PriceMaster> price = priceMasterRepository.findCurrentEffective(
                vehicle.getModelYear(), vehicle.getMakeCode(), vehicle.getModelCode(), LocalDate.now());
        return price.map(PriceMaster::getInvoicePrice).orElse(BigDecimal.ZERO);
    }

    /**
     * Determine the aging bucket index for a given number of days.
     */
    private int determineBucketIndex(long days) {
        for (int i = 0; i < AGING_BOUNDARIES.length; i++) {
            if (days <= AGING_BOUNDARIES[i]) {
                return i;
            }
        }
        return AGING_BOUNDARIES.length; // 120+ bucket
    }

    /**
     * Map a status code to its display name.
     */
    private String getStatusName(String code) {
        return STATUS_NAMES.getOrDefault(code, code);
    }

    /**
     * Build a full VehicleResponse with options and history.
     */
    private VehicleResponse toResponse(Vehicle vehicle, List<VehicleOption> options,
                                        List<VehicleStatusHist> history) {
        String vehicleDesc = vehicle.getModelYear() + " " + vehicle.getMakeCode() + " " + vehicle.getModelCode();

        List<VehicleOptionResponse> optionResponses = options.stream()
                .map(o -> VehicleOptionResponse.builder()
                        .optionCode(o.getOptionCode())
                        .optionDesc(o.getOptionDesc())
                        .optionPrice(o.getOptionPrice())
                        .installedFlag(o.getInstalledFlag())
                        .build())
                .toList();

        List<VehicleHistoryEntry> historyEntries = history.stream()
                .map(this::toHistoryEntry)
                .toList();

        return VehicleResponse.builder()
                .vin(vehicle.getVin())
                .modelYear(vehicle.getModelYear())
                .makeCode(vehicle.getMakeCode())
                .modelCode(vehicle.getModelCode())
                .exteriorColor(vehicle.getExteriorColor())
                .interiorColor(vehicle.getInteriorColor())
                .engineNum(vehicle.getEngineNum())
                .productionDate(vehicle.getProductionDate())
                .shipDate(vehicle.getShipDate())
                .receiveDate(vehicle.getReceiveDate())
                .vehicleStatus(vehicle.getVehicleStatus())
                .statusName(getStatusName(vehicle.getVehicleStatus()))
                .dealerCode(vehicle.getDealerCode())
                .lotLocation(vehicle.getLotLocation())
                .stockNumber(vehicle.getStockNumber())
                .daysInStock(vehicle.getDaysInStock())
                .pdiComplete(vehicle.getPdiComplete())
                .damageFlag(vehicle.getDamageFlag())
                .damageDesc(vehicle.getDamageDesc())
                .odometer(vehicle.getOdometer())
                .keyNumber(vehicle.getKeyNumber())
                .vehicleDesc(vehicleDesc)
                .options(optionResponses)
                .history(historyEntries)
                .createdTs(vehicle.getCreatedTs())
                .updatedTs(vehicle.getUpdatedTs())
                .build();
    }

    /**
     * Build a compact VehicleListResponse for list/search results.
     */
    private VehicleListResponse toListResponse(Vehicle vehicle) {
        String vehicleDesc = vehicle.getModelYear() + " " + vehicle.getMakeCode() + " " + vehicle.getModelCode();

        return VehicleListResponse.builder()
                .vin(vehicle.getVin())
                .stockNumber(vehicle.getStockNumber())
                .vehicleDesc(vehicleDesc)
                .vehicleStatus(vehicle.getVehicleStatus())
                .statusName(getStatusName(vehicle.getVehicleStatus()))
                .exteriorColor(vehicle.getExteriorColor())
                .daysInStock(vehicle.getDaysInStock())
                .dealerCode(vehicle.getDealerCode())
                .lotLocation(vehicle.getLotLocation())
                .pdiComplete(vehicle.getPdiComplete())
                .damageFlag(vehicle.getDamageFlag())
                .build();
    }

    /**
     * Map a VehicleStatusHist entity to a VehicleHistoryEntry DTO.
     */
    private VehicleHistoryEntry toHistoryEntry(VehicleStatusHist hist) {
        return VehicleHistoryEntry.builder()
                .statusSeq(hist.getStatusSeq())
                .oldStatus(hist.getOldStatus())
                .newStatus(hist.getNewStatus())
                .changedBy(hist.getChangedBy())
                .changeReason(hist.getChangeReason())
                .changedTs(hist.getChangedTs())
                .build();
    }
}
