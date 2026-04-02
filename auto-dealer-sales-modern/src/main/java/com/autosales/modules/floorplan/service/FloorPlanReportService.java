package com.autosales.modules.floorplan.service;

import com.autosales.modules.floorplan.dto.FloorPlanExposureResponse;
import com.autosales.modules.floorplan.entity.FloorPlanLender;
import com.autosales.modules.floorplan.entity.FloorPlanVehicle;
import com.autosales.modules.floorplan.repository.FloorPlanLenderRepository;
import com.autosales.modules.floorplan.repository.FloorPlanVehicleRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Floor plan exposure reporting service.
 * Port of FPLRPT00.cbl — floor plan exposure report transaction.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class FloorPlanReportService {

    private static final int MONEY_SCALE = 2;
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    private final FloorPlanVehicleRepository floorPlanVehicleRepository;
    private final FloorPlanLenderRepository floorPlanLenderRepository;
    private final VehicleRepository vehicleRepository;

    /**
     * Generate a floor plan exposure report for a dealer.
     */
    public FloorPlanExposureResponse generateExposureReport(String dealerCode) {
        log.info("Generating floor plan exposure report for dealer={}", dealerCode);

        LocalDate today = LocalDate.now();

        // Fetch all active floor plan vehicles for this dealer
        List<FloorPlanVehicle> activeVehicles = floorPlanVehicleRepository
                .findByDealerCodeAndFpStatus(dealerCode, "AC");

        if (activeVehicles.isEmpty()) {
            return FloorPlanExposureResponse.builder()
                    .dealerCode(dealerCode)
                    .grandTotals(FloorPlanExposureResponse.GrandTotals.builder()
                            .totalVehicles(0)
                            .totalBalance(BigDecimal.ZERO)
                            .totalInterest(BigDecimal.ZERO)
                            .weightedAvgRate(BigDecimal.ZERO)
                            .avgDaysOnFloor(0)
                            .build())
                    .lenderBreakdown(List.of())
                    .newUsedSplit(FloorPlanExposureResponse.NewUsedSplit.builder()
                            .newCount(0).usedCount(0)
                            .newBalance(BigDecimal.ZERO).usedBalance(BigDecimal.ZERO)
                            .build())
                    .ageBuckets(FloorPlanExposureResponse.AgeBuckets.builder()
                            .count0to30(0).count31to60(0).count61to90(0).count91plus(0)
                            .build())
                    .build();
        }

        // Load all lenders into a map for quick lookup
        Map<String, FloorPlanLender> lenderMap = floorPlanLenderRepository.findAll().stream()
                .collect(Collectors.toMap(FloorPlanLender::getLenderId, l -> l, (a, b) -> a));

        // --- Grand totals ---
        int totalVehicles = activeVehicles.size();
        BigDecimal totalBalance = BigDecimal.ZERO;
        BigDecimal totalInterest = BigDecimal.ZERO;
        BigDecimal weightedRateSum = BigDecimal.ZERO;
        long totalDays = 0;

        // --- New/Used split ---
        int newCount = 0;
        int usedCount = 0;
        BigDecimal newBalance = BigDecimal.ZERO;
        BigDecimal usedBalance = BigDecimal.ZERO;

        // --- Age buckets ---
        int count0to30 = 0;
        int count31to60 = 0;
        int count61to90 = 0;
        int count91plus = 0;

        // --- Lender breakdown accumulators ---
        // lenderId -> {vehicleCount, balance, interest, rateSum, daysSum}
        Map<String, LenderAccumulator> lenderAccumulators = new LinkedHashMap<>();

        for (FloorPlanVehicle fpv : activeVehicles) {
            BigDecimal balance = fpv.getCurrentBalance();
            BigDecimal interest = fpv.getInterestAccrued();
            long daysOnFloor = ChronoUnit.DAYS.between(fpv.getFloorDate(), today);

            totalBalance = totalBalance.add(balance);
            totalInterest = totalInterest.add(interest);
            totalDays += daysOnFloor;

            // Get effective rate for this vehicle's lender
            FloorPlanLender lender = lenderMap.get(fpv.getLenderId());
            BigDecimal effectiveRate = lender != null
                    ? lender.getBaseRate().add(lender.getSpread())
                    : BigDecimal.ZERO;
            weightedRateSum = weightedRateSum.add(effectiveRate.multiply(balance));

            // Lender breakdown
            lenderAccumulators.computeIfAbsent(fpv.getLenderId(),
                    k -> new LenderAccumulator(lender != null ? lender.getLenderName() : fpv.getLenderId()));
            LenderAccumulator acc = lenderAccumulators.get(fpv.getLenderId());
            acc.vehicleCount++;
            acc.balance = acc.balance.add(balance);
            acc.interest = acc.interest.add(interest);
            acc.rateSum = acc.rateSum.add(effectiveRate);
            acc.daysSum += daysOnFloor;

            // New/Used split — join with Vehicle entity
            Optional<Vehicle> vehicle = vehicleRepository.findById(fpv.getVin());
            boolean isNew = true; // default to new
            if (vehicle.isPresent()) {
                short modelYear = vehicle.get().getModelYear();
                // Consider vehicles with model year < current year - 1 as used
                isNew = modelYear >= (short) (today.getYear() - 1);
            }
            if (isNew) {
                newCount++;
                newBalance = newBalance.add(balance);
            } else {
                usedCount++;
                usedBalance = usedBalance.add(balance);
            }

            // Age buckets
            if (daysOnFloor <= 30) {
                count0to30++;
            } else if (daysOnFloor <= 60) {
                count31to60++;
            } else if (daysOnFloor <= 90) {
                count61to90++;
            } else {
                count91plus++;
            }
        }

        // Weighted average rate
        BigDecimal weightedAvgRate = totalBalance.signum() != 0
                ? weightedRateSum.divide(totalBalance, 4, ROUNDING)
                : BigDecimal.ZERO;

        int avgDaysOnFloor = totalVehicles > 0 ? (int) (totalDays / totalVehicles) : 0;

        // Build grand totals
        FloorPlanExposureResponse.GrandTotals grandTotals = FloorPlanExposureResponse.GrandTotals.builder()
                .totalVehicles(totalVehicles)
                .totalBalance(totalBalance.setScale(MONEY_SCALE, ROUNDING))
                .totalInterest(totalInterest.setScale(MONEY_SCALE, ROUNDING))
                .weightedAvgRate(weightedAvgRate.setScale(MONEY_SCALE, ROUNDING))
                .avgDaysOnFloor(avgDaysOnFloor)
                .build();

        // Build lender breakdown
        List<FloorPlanExposureResponse.LenderBreakdown> lenderBreakdown = lenderAccumulators.entrySet().stream()
                .map(e -> {
                    LenderAccumulator a = e.getValue();
                    BigDecimal avgRate = a.vehicleCount > 0
                            ? a.rateSum.divide(new BigDecimal(a.vehicleCount), 4, ROUNDING)
                            : BigDecimal.ZERO;
                    int avgDays = a.vehicleCount > 0 ? (int) (a.daysSum / a.vehicleCount) : 0;
                    return FloorPlanExposureResponse.LenderBreakdown.builder()
                            .lenderId(e.getKey())
                            .lenderName(a.lenderName)
                            .vehicleCount(a.vehicleCount)
                            .balance(a.balance.setScale(MONEY_SCALE, ROUNDING))
                            .interest(a.interest.setScale(MONEY_SCALE, ROUNDING))
                            .avgRate(avgRate.setScale(MONEY_SCALE, ROUNDING))
                            .avgDays(avgDays)
                            .build();
                })
                .toList();

        // Build new/used split
        FloorPlanExposureResponse.NewUsedSplit newUsedSplit = FloorPlanExposureResponse.NewUsedSplit.builder()
                .newCount(newCount)
                .usedCount(usedCount)
                .newBalance(newBalance.setScale(MONEY_SCALE, ROUNDING))
                .usedBalance(usedBalance.setScale(MONEY_SCALE, ROUNDING))
                .build();

        // Build age buckets
        FloorPlanExposureResponse.AgeBuckets ageBuckets = FloorPlanExposureResponse.AgeBuckets.builder()
                .count0to30(count0to30)
                .count31to60(count31to60)
                .count61to90(count61to90)
                .count91plus(count91plus)
                .build();

        log.info("Exposure report complete for dealer={}: {} vehicles, total balance={}",
                dealerCode, totalVehicles, totalBalance);
        return FloorPlanExposureResponse.builder()
                .dealerCode(dealerCode)
                .grandTotals(grandTotals)
                .lenderBreakdown(lenderBreakdown)
                .newUsedSplit(newUsedSplit)
                .ageBuckets(ageBuckets)
                .build();
    }

    /**
     * Internal accumulator for lender breakdown aggregation.
     */
    private static class LenderAccumulator {
        String lenderName;
        int vehicleCount = 0;
        BigDecimal balance = BigDecimal.ZERO;
        BigDecimal interest = BigDecimal.ZERO;
        BigDecimal rateSum = BigDecimal.ZERO;
        long daysSum = 0;

        LenderAccumulator(String lenderName) {
            this.lenderName = lenderName;
        }
    }
}
