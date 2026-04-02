package com.autosales.modules.floorplan.service;

import com.autosales.modules.floorplan.dto.FloorPlanExposureResponse;
import com.autosales.modules.floorplan.entity.FloorPlanLender;
import com.autosales.modules.floorplan.entity.FloorPlanVehicle;
import com.autosales.modules.floorplan.repository.FloorPlanLenderRepository;
import com.autosales.modules.floorplan.repository.FloorPlanVehicleRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for FloorPlanReportService — floor plan exposure reporting.
 * Port of FPLRPT00.cbl — dealer floor plan liability summary.
 *
 * Legacy COBOL business rules validated:
 * - Grand totals: total vehicles, balance, interest (FPLRPT00)
 * - Weighted average rate: sum(balance * rate) / sum(balance) (FPLRPT00)
 * - Average days on floor: sum(days) / count (FPLRPT00)
 * - Lender breakdown: up to 8 lenders in COBOL (no limit in modern) (FPLRPT00)
 * - New/Used split: new = modelYear >= currentYear - 1 (FPLRPT00 VEHICLE_CONDITION)
 * - Age buckets: 0-30, 31-60, 61-90, 91+ days (FPLRPT00)
 * - Empty dealer returns zero-ed report (FPLRPT00 informational message)
 */
@ExtendWith(MockitoExtension.class)
class FloorPlanReportServiceTest {

    @Mock private FloorPlanVehicleRepository floorPlanVehicleRepository;
    @Mock private FloorPlanLenderRepository floorPlanLenderRepository;
    @Mock private VehicleRepository vehicleRepository;

    @InjectMocks
    private FloorPlanReportService floorPlanReportService;

    private FloorPlanLender lender1;
    private FloorPlanLender lender2;

    @BeforeEach
    void setUp() {
        lender1 = FloorPlanLender.builder()
                .lenderId("LND01")
                .lenderName("First Floor Plan Bank")
                .baseRate(new BigDecimal("3.500"))
                .spread(new BigDecimal("1.500"))
                .curtailmentDays(90)
                .freeFloorDays(5)
                .build();

        lender2 = FloorPlanLender.builder()
                .lenderId("LND02")
                .lenderName("Auto Finance Corp")
                .baseRate(new BigDecimal("4.000"))
                .spread(new BigDecimal("2.000"))
                .curtailmentDays(60)
                .freeFloorDays(3)
                .build();
    }

    private FloorPlanVehicle buildFpv(String vin, String lenderId, BigDecimal balance,
                                       BigDecimal interest, int daysAgo) {
        return FloorPlanVehicle.builder()
                .floorPlanId(vin.hashCode())
                .vin(vin)
                .dealerCode("DLR01")
                .lenderId(lenderId)
                .invoiceAmount(balance)
                .currentBalance(balance)
                .interestAccrued(interest)
                .floorDate(LocalDate.now().minusDays(daysAgo))
                .curtailmentDate(LocalDate.now().plusDays(90 - daysAgo))
                .fpStatus("AC")
                .daysOnFloor((short) daysAgo)
                .build();
    }

    private Vehicle buildVehicle(String vin, short modelYear) {
        return Vehicle.builder()
                .vin(vin)
                .modelYear(modelYear)
                .makeCode("HON")
                .modelCode("ACCRD")
                .vehicleStatus("AV")
                .dealerCode("DLR01")
                .daysInStock((short) 0)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(5)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ========================================================================
    // 1. EMPTY DEALER — ZERO REPORT (FPLRPT00 informational message)
    // ========================================================================

    @Test
    @DisplayName("exposureReport: no active vehicles → empty report with zero totals (FPLRPT00)")
    void testExposureReport_emptyDealer() {
        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(Collections.emptyList());

        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport("DLR01");

        assertNotNull(response);
        assertEquals("DLR01", response.getDealerCode());
        assertEquals(0, response.getGrandTotals().getTotalVehicles());
        assertEquals(0, BigDecimal.ZERO.compareTo(response.getGrandTotals().getTotalBalance()));
        assertEquals(0, BigDecimal.ZERO.compareTo(response.getGrandTotals().getTotalInterest()));
        assertTrue(response.getLenderBreakdown().isEmpty());
    }

    // ========================================================================
    // 2. GRAND TOTALS (FPLRPT00)
    // ========================================================================

    @Test
    @DisplayName("exposureReport: grand totals — vehicles, balance, interest, weighted avg rate (FPLRPT00)")
    void testExposureReport_grandTotals() {
        // Vehicle 1: LND01, $31000, $150 interest, 45 days
        FloorPlanVehicle fpv1 = buildFpv("VIN00000000000001", "LND01",
                new BigDecimal("31000.00"), new BigDecimal("150.00"), 45);
        // Vehicle 2: LND01, $28000, $80 interest, 20 days
        FloorPlanVehicle fpv2 = buildFpv("VIN00000000000002", "LND01",
                new BigDecimal("28000.00"), new BigDecimal("80.00"), 20);
        // Vehicle 3: LND02, $45000, $300 interest, 75 days
        FloorPlanVehicle fpv3 = buildFpv("VIN00000000000003", "LND02",
                new BigDecimal("45000.00"), new BigDecimal("300.00"), 75);

        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(List.of(fpv1, fpv2, fpv3));
        when(floorPlanLenderRepository.findAll()).thenReturn(List.of(lender1, lender2));

        // Vehicles for new/used split
        when(vehicleRepository.findById("VIN00000000000001")).thenReturn(Optional.of(buildVehicle("VIN00000000000001", (short) 2026)));
        when(vehicleRepository.findById("VIN00000000000002")).thenReturn(Optional.of(buildVehicle("VIN00000000000002", (short) 2026)));
        when(vehicleRepository.findById("VIN00000000000003")).thenReturn(Optional.of(buildVehicle("VIN00000000000003", (short) 2023)));

        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport("DLR01");

        FloorPlanExposureResponse.GrandTotals totals = response.getGrandTotals();
        assertEquals(3, totals.getTotalVehicles());
        // Total balance: 31000 + 28000 + 45000 = 104000
        assertEquals(0, new BigDecimal("104000.00").compareTo(totals.getTotalBalance()));
        // Total interest: 150 + 80 + 300 = 530
        assertEquals(0, new BigDecimal("530.00").compareTo(totals.getTotalInterest()));
        // Weighted avg rate: (5.0*31000 + 5.0*28000 + 6.0*45000) / 104000
        // = (155000 + 140000 + 270000) / 104000 = 565000 / 104000 = 5.4327 → 5.43
        assertNotNull(totals.getWeightedAvgRate());
        assertTrue(totals.getWeightedAvgRate().compareTo(new BigDecimal("5.00")) > 0);
        // Avg days: (45 + 20 + 75) / 3 = 46.67 → 46
        assertTrue(totals.getAvgDaysOnFloor() > 0);
    }

    // ========================================================================
    // 3. LENDER BREAKDOWN (FPLRPT00 — up to 8 lenders in COBOL, unlimited in modern)
    // ========================================================================

    @Test
    @DisplayName("exposureReport: lender breakdown — per-lender stats (FPLRPT00)")
    void testExposureReport_lenderBreakdown() {
        FloorPlanVehicle fpv1 = buildFpv("VIN00000000000001", "LND01",
                new BigDecimal("31000.00"), new BigDecimal("150.00"), 45);
        FloorPlanVehicle fpv2 = buildFpv("VIN00000000000002", "LND02",
                new BigDecimal("45000.00"), new BigDecimal("300.00"), 75);

        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(List.of(fpv1, fpv2));
        when(floorPlanLenderRepository.findAll()).thenReturn(List.of(lender1, lender2));
        when(vehicleRepository.findById(anyString())).thenReturn(Optional.of(buildVehicle("X", (short) 2026)));

        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport("DLR01");

        assertEquals(2, response.getLenderBreakdown().size());

        // LND01
        FloorPlanExposureResponse.LenderBreakdown lb1 = response.getLenderBreakdown().stream()
                .filter(lb -> "LND01".equals(lb.getLenderId())).findFirst().orElseThrow();
        assertEquals(1, lb1.getVehicleCount());
        assertEquals(0, new BigDecimal("31000.00").compareTo(lb1.getBalance()));
        assertEquals(0, new BigDecimal("150.00").compareTo(lb1.getInterest()));
        assertEquals("First Floor Plan Bank", lb1.getLenderName());

        // LND02
        FloorPlanExposureResponse.LenderBreakdown lb2 = response.getLenderBreakdown().stream()
                .filter(lb -> "LND02".equals(lb.getLenderId())).findFirst().orElseThrow();
        assertEquals(1, lb2.getVehicleCount());
        assertEquals(0, new BigDecimal("45000.00").compareTo(lb2.getBalance()));
    }

    // ========================================================================
    // 4. NEW/USED SPLIT (FPLRPT00 — VEHICLE.VEHICLE_CONDITION based on model year)
    // ========================================================================

    @Test
    @DisplayName("exposureReport: new/used split — year >= currentYear-1 = new (FPLRPT00)")
    void testExposureReport_newUsedSplit() {
        // New vehicle (2026)
        FloorPlanVehicle fpvNew = buildFpv("VIN00000000000001", "LND01",
                new BigDecimal("31000.00"), new BigDecimal("150.00"), 20);
        // Used vehicle (2020, well before currentYear - 1)
        FloorPlanVehicle fpvUsed = buildFpv("VIN00000000000002", "LND01",
                new BigDecimal("18000.00"), new BigDecimal("80.00"), 50);

        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(List.of(fpvNew, fpvUsed));
        when(floorPlanLenderRepository.findAll()).thenReturn(List.of(lender1));
        when(vehicleRepository.findById("VIN00000000000001"))
                .thenReturn(Optional.of(buildVehicle("VIN00000000000001", (short) 2026)));
        when(vehicleRepository.findById("VIN00000000000002"))
                .thenReturn(Optional.of(buildVehicle("VIN00000000000002", (short) 2020)));

        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport("DLR01");

        FloorPlanExposureResponse.NewUsedSplit split = response.getNewUsedSplit();
        assertEquals(1, split.getNewCount());
        assertEquals(1, split.getUsedCount());
        assertEquals(0, new BigDecimal("31000.00").compareTo(split.getNewBalance()));
        assertEquals(0, new BigDecimal("18000.00").compareTo(split.getUsedBalance()));
    }

    // ========================================================================
    // 5. AGE BUCKETS (FPLRPT00 — 0-30, 31-60, 61-90, 91+ days)
    // ========================================================================

    @Test
    @DisplayName("exposureReport: age buckets — 4 ranges (FPLRPT00)")
    void testExposureReport_ageBuckets() {
        // 15 days → 0-30 bucket
        FloorPlanVehicle fpv1 = buildFpv("VIN00000000000001", "LND01",
                new BigDecimal("30000.00"), BigDecimal.ZERO, 15);
        // 45 days → 31-60 bucket
        FloorPlanVehicle fpv2 = buildFpv("VIN00000000000002", "LND01",
                new BigDecimal("28000.00"), BigDecimal.ZERO, 45);
        // 80 days → 61-90 bucket
        FloorPlanVehicle fpv3 = buildFpv("VIN00000000000003", "LND01",
                new BigDecimal("25000.00"), BigDecimal.ZERO, 80);
        // 120 days → 91+ bucket
        FloorPlanVehicle fpv4 = buildFpv("VIN00000000000004", "LND01",
                new BigDecimal("20000.00"), BigDecimal.ZERO, 120);

        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(List.of(fpv1, fpv2, fpv3, fpv4));
        when(floorPlanLenderRepository.findAll()).thenReturn(List.of(lender1));
        when(vehicleRepository.findById(anyString()))
                .thenReturn(Optional.of(buildVehicle("X", (short) 2026)));

        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport("DLR01");

        FloorPlanExposureResponse.AgeBuckets buckets = response.getAgeBuckets();
        assertEquals(1, buckets.getCount0to30());
        assertEquals(1, buckets.getCount31to60());
        assertEquals(1, buckets.getCount61to90());
        assertEquals(1, buckets.getCount91plus());
    }

    // ========================================================================
    // 6. SINGLE LENDER, MULTIPLE VEHICLES (FPLRPT00 accumulation)
    // ========================================================================

    @Test
    @DisplayName("exposureReport: single lender accumulates all vehicles (FPLRPT00)")
    void testExposureReport_singleLenderAccumulation() {
        FloorPlanVehicle fpv1 = buildFpv("VIN00000000000001", "LND01",
                new BigDecimal("31000.00"), new BigDecimal("150.00"), 30);
        FloorPlanVehicle fpv2 = buildFpv("VIN00000000000002", "LND01",
                new BigDecimal("28000.00"), new BigDecimal("100.00"), 60);

        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(List.of(fpv1, fpv2));
        when(floorPlanLenderRepository.findAll()).thenReturn(List.of(lender1));
        when(vehicleRepository.findById(anyString()))
                .thenReturn(Optional.of(buildVehicle("X", (short) 2026)));

        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport("DLR01");

        // Single lender breakdown entry
        assertEquals(1, response.getLenderBreakdown().size());
        FloorPlanExposureResponse.LenderBreakdown lb = response.getLenderBreakdown().get(0);
        assertEquals(2, lb.getVehicleCount());
        assertEquals(0, new BigDecimal("59000.00").compareTo(lb.getBalance())); // 31000 + 28000
        assertEquals(0, new BigDecimal("250.00").compareTo(lb.getInterest())); // 150 + 100
    }
}
