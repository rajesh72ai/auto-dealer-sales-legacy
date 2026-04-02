package com.autosales.modules.floorplan.service;

import com.autosales.common.audit.Auditable;
import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.FloorPlanInterestCalculator;
import com.autosales.common.util.FloorPlanInterestCalculator.DayCountBasis;
import com.autosales.common.util.FloorPlanInterestResult;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.modules.floorplan.dto.*;
import com.autosales.modules.floorplan.entity.FloorPlanInterest;
import com.autosales.modules.floorplan.entity.FloorPlanLender;
import com.autosales.modules.floorplan.entity.FloorPlanVehicle;
import com.autosales.modules.floorplan.repository.FloorPlanInterestRepository;
import com.autosales.modules.floorplan.repository.FloorPlanLenderRepository;
import com.autosales.modules.floorplan.repository.FloorPlanVehicleRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
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
import java.util.Optional;

/**
 * Service for floor plan vehicle financing management.
 * Port of FPLADD00.cbl (add), FPLINQ00.cbl (inquiry),
 * FPLINT00.cbl (interest), FPLPAY00.cbl (payoff).
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class FloorPlanService {

    private static final int MONEY_SCALE = 2;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    private final FloorPlanVehicleRepository floorPlanVehicleRepository;
    private final FloorPlanLenderRepository floorPlanLenderRepository;
    private final FloorPlanInterestRepository floorPlanInterestRepository;
    private final VehicleRepository vehicleRepository;
    private final FloorPlanInterestCalculator interestCalculator;
    private final FieldFormatter fieldFormatter;

    /**
     * List floor plan vehicles for a dealer with optional filters.
     */
    public PaginatedResponse<FloorPlanVehicleResponse> listFloorPlanVehicles(String dealerCode, String status,
                                                                              String lenderId, int page, int size) {
        log.debug("Listing floor plan vehicles - dealer={}, status={}, lender={}", dealerCode, status, lenderId);

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "floorDate"));
        Page<FloorPlanVehicle> result;

        if (status != null && !status.isBlank()) {
            result = floorPlanVehicleRepository.findByDealerCodeAndFpStatus(dealerCode, status, pageable);
        } else {
            result = floorPlanVehicleRepository.findByDealerCode(dealerCode, pageable);
        }

        List<FloorPlanVehicleResponse> content = result.getContent().stream()
                .map(this::toResponse)
                .toList();

        // Post-filter by lender if specified (not a repo-level filter)
        if (lenderId != null && !lenderId.isBlank()) {
            content = content.stream()
                    .filter(v -> lenderId.equals(v.getLenderId()))
                    .toList();
        }

        return new PaginatedResponse<>("success", null, content,
                result.getNumber(), result.getTotalPages(), result.getTotalElements(), LocalDateTime.now());
    }

    /**
     * Add a vehicle to floor plan financing.
     */
    @Transactional
    @Auditable(action = "INS", entity = "floor_plan_vehicle", keyExpression = "#request.vin")
    public FloorPlanVehicleResponse addVehicleToFloorPlan(FloorPlanAddRequest request) {
        log.info("Adding vehicle to floor plan vin={}, dealer={}", request.getVin(), request.getDealerCode());

        // Validate VIN exists
        Vehicle vehicle = vehicleRepository.findById(request.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", request.getVin()));

        // Validate vehicle status is AV or IT
        if (!"AV".equals(vehicle.getVehicleStatus()) && !"IT".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle must be in Available (AV) or In-Transit (IT) status. Current: "
                            + vehicle.getVehicleStatus());
        }

        // Validate lender exists
        FloorPlanLender lender = floorPlanLenderRepository.findByLenderId(request.getLenderId())
                .orElseThrow(() -> new EntityNotFoundException("FloorPlanLender", request.getLenderId()));

        // Invoice amount defaults to vehicle's invoice price (via price master if needed)
        BigDecimal invoiceAmount = request.getInvoiceAmount();
        if (invoiceAmount == null) {
            // Default: use a reasonable fallback — typically the invoice amount would come from pricing
            throw new BusinessValidationException("Invoice amount is required");
        }

        // Floor date defaults to today
        LocalDate floorDate = request.getFloorDate() != null ? request.getFloorDate() : LocalDate.now();

        // Curtailment date = floorDate + lender.curtailmentDays
        LocalDate curtailmentDate = floorDate.plusDays(lender.getCurtailmentDays());

        FloorPlanVehicle entity = FloorPlanVehicle.builder()
                .vin(request.getVin())
                .dealerCode(request.getDealerCode())
                .lenderId(request.getLenderId())
                .invoiceAmount(invoiceAmount)
                .currentBalance(invoiceAmount)
                .interestAccrued(BigDecimal.ZERO)
                .floorDate(floorDate)
                .curtailmentDate(curtailmentDate)
                .fpStatus("AC")
                .daysOnFloor((short) 0)
                .build();

        FloorPlanVehicle saved = floorPlanVehicleRepository.save(entity);
        log.info("Added vehicle to floor plan id={}, vin={}", saved.getFloorPlanId(), saved.getVin());
        return toResponse(saved);
    }

    /**
     * Pay off a floor plan vehicle.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "floor_plan_vehicle", keyExpression = "#request.vin")
    public FloorPlanPayoffResponse payoffFloorPlan(FloorPlanPayoffRequest request) {
        log.info("Paying off floor plan for vin={}", request.getVin());

        // Find active floor plan for VIN
        FloorPlanVehicle fpv = floorPlanVehicleRepository.findByVinAndFpStatus(request.getVin(), "AC")
                .orElseThrow(() -> new EntityNotFoundException("FloorPlanVehicle (active)", request.getVin()));

        // Get lender for rate
        FloorPlanLender lender = floorPlanLenderRepository.findByLenderId(fpv.getLenderId())
                .orElse(null);
        BigDecimal effectiveRate = lender != null
                ? lender.getBaseRate().add(lender.getSpread())
                : new BigDecimal("5.00");

        // Calculate final interest from floor date to today
        LocalDate today = LocalDate.now();
        BigDecimal finalInterest = interestCalculator.calculateRangeInterest(
                fpv.getCurrentBalance(), effectiveRate, DayCountBasis.ACTUAL_365,
                fpv.getFloorDate(), today);

        BigDecimal totalPayoff = fpv.getCurrentBalance().add(finalInterest)
                .setScale(MONEY_SCALE, ROUNDING);
        BigDecimal originalBalance = fpv.getCurrentBalance();
        int daysOnFloor = (int) ChronoUnit.DAYS.between(fpv.getFloorDate(), today);

        // Update floor plan
        fpv.setFpStatus("PD");
        fpv.setPayoffDate(today);
        fpv.setInterestAccrued(fpv.getInterestAccrued().add(finalInterest));
        fpv.setCurrentBalance(BigDecimal.ZERO);
        fpv.setDaysOnFloor((short) daysOnFloor);
        floorPlanVehicleRepository.save(fpv);

        log.info("Floor plan paid off id={}, vin={}, payoff={}", fpv.getFloorPlanId(), request.getVin(), totalPayoff);
        return FloorPlanPayoffResponse.builder()
                .vin(request.getVin())
                .floorPlanId(fpv.getFloorPlanId())
                .lenderId(fpv.getLenderId())
                .originalFloorDate(fpv.getFloorDate())
                .payoffDate(today)
                .originalBalance(originalBalance)
                .finalInterest(finalInterest)
                .totalPayoff(totalPayoff)
                .daysOnFloor(daysOnFloor)
                .status("PD")
                .build();
    }

    /**
     * Calculate and accrue interest — single vehicle or batch by dealer.
     */
    @Transactional
    @Auditable(action = "UPD", entity = "floor_plan_interest", keyExpression = "#request.mode")
    public FloorPlanInterestResponse calculateInterest(FloorPlanInterestRequest request) {
        log.info("Calculating floor plan interest mode={}", request.getMode());

        List<FloorPlanVehicle> vehicles;
        if ("SINGLE".equals(request.getMode())) {
            if (request.getVin() == null || request.getVin().isBlank()) {
                throw new BusinessValidationException("VIN is required for SINGLE mode");
            }
            FloorPlanVehicle fpv = floorPlanVehicleRepository.findByVinAndFpStatus(request.getVin(), "AC")
                    .orElseThrow(() -> new EntityNotFoundException("FloorPlanVehicle (active)", request.getVin()));
            vehicles = List.of(fpv);
        } else {
            // BATCH mode
            if (request.getDealerCode() == null || request.getDealerCode().isBlank()) {
                throw new BusinessValidationException("Dealer code is required for BATCH mode");
            }
            vehicles = floorPlanVehicleRepository.findByDealerCodeAndFpStatus(request.getDealerCode(), "AC");
        }

        int processedCount = 0;
        int updatedCount = 0;
        int curtailmentWarningCount = 0;
        int errorCount = 0;
        BigDecimal totalInterestAmount = BigDecimal.ZERO;
        List<FloorPlanInterestResponse.InterestDetail> details = new ArrayList<>();
        LocalDate today = LocalDate.now();

        for (FloorPlanVehicle fpv : vehicles) {
            processedCount++;
            try {
                // Get lender rate
                FloorPlanLender lender = floorPlanLenderRepository.findByLenderId(fpv.getLenderId())
                        .orElse(null);
                BigDecimal effectiveRate = lender != null
                        ? lender.getBaseRate().add(lender.getSpread())
                        : new BigDecimal("5.00");

                // Determine vehicle type for curtailment check
                Vehicle vehicle = vehicleRepository.findById(fpv.getVin()).orElse(null);
                String vehicleType = "NEW"; // default
                if (vehicle != null && vehicle.getVehicleStatus() != null) {
                    // Use model year to determine: current/next year = NEW, older = USED
                    if (vehicle.getModelYear() < (short) (LocalDate.now().getYear() - 1)) {
                        vehicleType = "USED";
                    }
                }

                // Calculate daily interest
                BigDecimal dailyInterest = interestCalculator.calculateDailyInterest(
                        fpv.getCurrentBalance(), effectiveRate, DayCountBasis.ACTUAL_365, today);

                // Update accrued interest
                BigDecimal newAccrued = fpv.getInterestAccrued().add(dailyInterest);
                fpv.setInterestAccrued(newAccrued);
                fpv.setLastInterestDt(today);
                int daysOnFloor = (int) ChronoUnit.DAYS.between(fpv.getFloorDate(), today);
                fpv.setDaysOnFloor((short) daysOnFloor);
                floorPlanVehicleRepository.save(fpv);

                // Insert interest detail record
                FloorPlanInterest interestRecord = FloorPlanInterest.builder()
                        .floorPlanId(fpv.getFloorPlanId())
                        .calcDate(today)
                        .principalBal(fpv.getCurrentBalance())
                        .rateApplied(effectiveRate)
                        .dailyInterest(dailyInterest)
                        .cumulativeInt(newAccrued)
                        .build();
                floorPlanInterestRepository.save(interestRecord);

                updatedCount++;
                totalInterestAmount = totalInterestAmount.add(dailyInterest);

                // Check curtailment warning
                int daysToCurtailment = fpv.getCurtailmentDate() != null
                        ? (int) ChronoUnit.DAYS.between(today, fpv.getCurtailmentDate())
                        : Integer.MAX_VALUE;
                boolean warning = daysToCurtailment <= 15;
                if (warning) {
                    curtailmentWarningCount++;
                }

                details.add(FloorPlanInterestResponse.InterestDetail.builder()
                        .vin(fpv.getVin())
                        .dailyInterest(dailyInterest)
                        .newAccrued(newAccrued)
                        .daysToCurtailment(daysToCurtailment < 0 ? 0 : daysToCurtailment)
                        .warning(warning)
                        .build());

            } catch (Exception e) {
                log.error("Error processing floor plan interest for vin={}: {}", fpv.getVin(), e.getMessage());
                errorCount++;
            }
        }

        log.info("Floor plan interest complete - processed={}, updated={}, warnings={}, errors={}",
                processedCount, updatedCount, curtailmentWarningCount, errorCount);
        return FloorPlanInterestResponse.builder()
                .mode(request.getMode())
                .processedCount(processedCount)
                .updatedCount(updatedCount)
                .curtailmentWarningCount(curtailmentWarningCount)
                .errorCount(errorCount)
                .totalInterestAmount(totalInterestAmount.setScale(MONEY_SCALE, ROUNDING))
                .details(details)
                .build();
    }

    /**
     * List all floor plan lenders.
     */
    public List<FloorPlanLenderResponse> listLenders() {
        log.debug("Listing all floor plan lenders");
        return floorPlanLenderRepository.findAllByOrderByLenderNameAsc().stream()
                .map(this::toLenderResponse)
                .toList();
    }

    // --- Private helpers ---

    private FloorPlanVehicleResponse toResponse(FloorPlanVehicle entity) {
        LocalDate today = LocalDate.now();
        int daysOnFloor = (int) ChronoUnit.DAYS.between(entity.getFloorDate(), today);
        Integer daysToCurtailment = entity.getCurtailmentDate() != null
                ? (int) ChronoUnit.DAYS.between(today, entity.getCurtailmentDate())
                : null;

        String statusName = switch (entity.getFpStatus()) {
            case "AC" -> "Active";
            case "PD" -> "Paid Off";
            default -> entity.getFpStatus();
        };

        // Build vehicle description from Vehicle entity
        String vehicleDescription = entity.getVin();
        Optional<Vehicle> vehicle = vehicleRepository.findById(entity.getVin());
        if (vehicle.isPresent()) {
            Vehicle v = vehicle.get();
            vehicleDescription = v.getModelYear() + " " + v.getMakeCode() + " " + v.getModelCode();
        }

        // Get lender name
        String lenderName = null;
        Optional<FloorPlanLender> lender = floorPlanLenderRepository.findByLenderId(entity.getLenderId());
        if (lender.isPresent()) {
            lenderName = lender.get().getLenderName();
        }

        return FloorPlanVehicleResponse.builder()
                .floorPlanId(entity.getFloorPlanId())
                .vin(entity.getVin())
                .dealerCode(entity.getDealerCode())
                .lenderId(entity.getLenderId())
                .lenderName(lenderName)
                .invoiceAmount(entity.getInvoiceAmount())
                .currentBalance(entity.getCurrentBalance())
                .interestAccrued(entity.getInterestAccrued())
                .floorDate(entity.getFloorDate())
                .curtailmentDate(entity.getCurtailmentDate())
                .payoffDate(entity.getPayoffDate())
                .fpStatus(entity.getFpStatus())
                .statusName(statusName)
                .daysOnFloor(daysOnFloor)
                .daysToCurtailment(daysToCurtailment)
                .vehicleDescription(vehicleDescription)
                .build();
    }

    private FloorPlanLenderResponse toLenderResponse(FloorPlanLender entity) {
        BigDecimal effectiveRate = entity.getBaseRate().add(entity.getSpread());

        return FloorPlanLenderResponse.builder()
                .lenderId(entity.getLenderId())
                .lenderName(entity.getLenderName())
                .contactName(entity.getContactName())
                .phone(entity.getPhone() != null ? fieldFormatter.formatPhone(entity.getPhone()) : null)
                .baseRate(entity.getBaseRate())
                .spread(entity.getSpread())
                .effectiveRate(effectiveRate)
                .curtailmentDays(entity.getCurtailmentDays())
                .freeFloorDays(entity.getFreeFloorDays())
                .build();
    }
}
