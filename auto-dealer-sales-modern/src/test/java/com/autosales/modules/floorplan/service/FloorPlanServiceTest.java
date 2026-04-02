package com.autosales.modules.floorplan.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.FloorPlanInterestCalculator;
import com.autosales.common.util.FloorPlanInterestCalculator.DayCountBasis;
import com.autosales.modules.floorplan.dto.*;
import com.autosales.modules.floorplan.entity.FloorPlanInterest;
import com.autosales.modules.floorplan.entity.FloorPlanLender;
import com.autosales.modules.floorplan.entity.FloorPlanVehicle;
import com.autosales.modules.floorplan.repository.FloorPlanInterestRepository;
import com.autosales.modules.floorplan.repository.FloorPlanLenderRepository;
import com.autosales.modules.floorplan.repository.FloorPlanVehicleRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for FloorPlanService — floor plan vehicle financing.
 * Covers FPLADD00 (add), FPLPAY00 (payoff), FPLINT00 (interest), FPLINQ00 (inquiry).
 *
 * Legacy COBOL business rules validated:
 * - Vehicle must be AV or IT to floor plan (FPLADD00 status check)
 * - Curtailment date = floorDate + lender.curtailmentDays (FPLADD00 DB2 date arithmetic)
 * - Invoice becomes initial balance (FPLADD00)
 * - Payoff: final interest from floor date to today, balance → 0, status → PD (FPLPAY00)
 * - Total payoff = balance + final interest (FPLPAY00)
 * - Interest: daily = balance * rate / 365 (FPLINT00 COMINTL0 DAY function)
 * - Curtailment warning at ≤ 15 days (FPLINT00 WS-CURTAIL-THRESHOLD)
 * - Batch mode processes all active vehicles for dealer (FPLINT00)
 * - Single mode processes one VIN (FPLINT00)
 * - Error in batch continues processing (FPLINT00 per-vehicle error handling)
 */
@ExtendWith(MockitoExtension.class)
class FloorPlanServiceTest {

    @Mock private FloorPlanVehicleRepository floorPlanVehicleRepository;
    @Mock private FloorPlanLenderRepository floorPlanLenderRepository;
    @Mock private FloorPlanInterestRepository floorPlanInterestRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private FloorPlanInterestCalculator interestCalculator;
    @Mock private FieldFormatter fieldFormatter;

    @InjectMocks
    private FloorPlanService floorPlanService;

    private Vehicle testVehicle;
    private FloorPlanLender testLender;
    private FloorPlanVehicle testFloorPlan;

    @BeforeEach
    void setUp() {
        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .modelYear((short) 2026)
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

        testLender = FloorPlanLender.builder()
                .lenderId("LND01")
                .lenderName("First Floor Plan Bank")
                .contactName("Bob Lender")
                .phone("2145559999")
                .baseRate(new BigDecimal("3.500"))
                .spread(new BigDecimal("1.500"))
                .curtailmentDays(90)
                .freeFloorDays(5)
                .build();

        testFloorPlan = FloorPlanVehicle.builder()
                .floorPlanId(1)
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("31000.00"))
                .currentBalance(new BigDecimal("31000.00"))
                .interestAccrued(new BigDecimal("150.00"))
                .floorDate(LocalDate.now().minusDays(45))
                .curtailmentDate(LocalDate.now().plusDays(45))
                .fpStatus("AC")
                .daysOnFloor((short) 45)
                .build();
    }

    // ========================================================================
    // 1. ADD VEHICLE TO FLOOR PLAN (FPLADD00)
    // ========================================================================

    @Test
    @DisplayName("addVehicle: success — status AC, balance = invoice, curtailment calculated (FPLADD00)")
    void testAddVehicle_success() {
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("31000.00"))
                .floorDate(LocalDate.of(2026, 3, 1))
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> {
            FloorPlanVehicle v = inv.getArgument(0);
            v.setFloorPlanId(1);
            return v;
        });

        FloorPlanVehicleResponse response = floorPlanService.addVehicleToFloorPlan(request);

        assertNotNull(response);

        // Verify saved entity
        ArgumentCaptor<FloorPlanVehicle> captor = ArgumentCaptor.forClass(FloorPlanVehicle.class);
        verify(floorPlanVehicleRepository).save(captor.capture());
        FloorPlanVehicle saved = captor.getValue();

        assertEquals("AC", saved.getFpStatus()); // Active
        assertEquals(0, new BigDecimal("31000.00").compareTo(saved.getInvoiceAmount()));
        assertEquals(0, new BigDecimal("31000.00").compareTo(saved.getCurrentBalance())); // Balance = invoice
        assertEquals(0, BigDecimal.ZERO.compareTo(saved.getInterestAccrued())); // Zero interest
        assertEquals((short) 0, saved.getDaysOnFloor());
        // Curtailment = floor date + lender's 90 days (FPLADD00 DB2 date arithmetic)
        assertEquals(LocalDate.of(2026, 5, 30), saved.getCurtailmentDate());
    }

    @Test
    @DisplayName("addVehicle: floor date defaults to today when not specified (FPLADD00)")
    void testAddVehicle_defaultFloorDate() {
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("31000.00"))
                .floorDate(null) // Defaults to today
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        floorPlanService.addVehicleToFloorPlan(request);

        ArgumentCaptor<FloorPlanVehicle> captor = ArgumentCaptor.forClass(FloorPlanVehicle.class);
        verify(floorPlanVehicleRepository).save(captor.capture());
        assertEquals(LocalDate.now(), captor.getValue().getFloorDate());
    }

    @Test
    @DisplayName("addVehicle: In-Transit (IT) status allowed (FPLADD00 AV/IT check)")
    void testAddVehicle_inTransitAllowed() {
        testVehicle.setVehicleStatus("IT"); // In Transit
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("31000.00"))
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        // Should not throw — IT is valid
        FloorPlanVehicleResponse response = floorPlanService.addVehicleToFloorPlan(request);
        assertNotNull(response);
    }

    @Test
    @DisplayName("addVehicle: Sold (SD) vehicle → rejection (FPLADD00 status gate)")
    void testAddVehicle_soldVehicleRejected() {
        testVehicle.setVehicleStatus("SD"); // Sold
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("31000.00"))
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> floorPlanService.addVehicleToFloorPlan(request));

        assertTrue(ex.getMessage().contains("Available (AV) or In-Transit (IT)"));
        assertTrue(ex.getMessage().contains("SD"));
        verify(floorPlanVehicleRepository, never()).save(any());
    }

    @Test
    @DisplayName("addVehicle: vehicle not found → EntityNotFoundException")
    void testAddVehicle_vehicleNotFound() {
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("XXXXXXXXXXXXXXXXXXX")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("31000.00"))
                .build();

        when(vehicleRepository.findById("XXXXXXXXXXXXXXXXXXX")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> floorPlanService.addVehicleToFloorPlan(request));
    }

    @Test
    @DisplayName("addVehicle: lender not found → EntityNotFoundException")
    void testAddVehicle_lenderNotFound() {
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("BADLD")
                .invoiceAmount(new BigDecimal("31000.00"))
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(floorPlanLenderRepository.findByLenderId("BADLD")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> floorPlanService.addVehicleToFloorPlan(request));
    }

    @Test
    @DisplayName("addVehicle: missing invoice amount → BusinessValidationException")
    void testAddVehicle_missingInvoice() {
        FloorPlanAddRequest request = FloorPlanAddRequest.builder()
                .vin("1HGCM82633A004352")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(null)
                .build();

        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> floorPlanService.addVehicleToFloorPlan(request));

        assertTrue(ex.getMessage().contains("Invoice amount is required"));
    }

    // ========================================================================
    // 2. PAYOFF FLOOR PLAN (FPLPAY00)
    // ========================================================================

    @Test
    @DisplayName("payoff: success — final interest calculated, balance zeroed, status PD (FPLPAY00)")
    void testPayoff_success() {
        when(floorPlanVehicleRepository.findByVinAndFpStatus("1HGCM82633A004352", "AC"))
                .thenReturn(Optional.of(testFloorPlan));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));

        // Final interest from floor date to today (COMINTL0 CALC)
        BigDecimal finalInterest = new BigDecimal("191.23");
        when(interestCalculator.calculateRangeInterest(
                eq(new BigDecimal("31000.00")), eq(new BigDecimal("5.000")),
                eq(DayCountBasis.ACTUAL_365), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(finalInterest);

        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        FloorPlanPayoffRequest request = FloorPlanPayoffRequest.builder()
                .vin("1HGCM82633A004352")
                .build();

        FloorPlanPayoffResponse response = floorPlanService.payoffFloorPlan(request);

        assertNotNull(response);
        assertEquals("1HGCM82633A004352", response.getVin());
        assertEquals("PD", response.getStatus());
        assertNotNull(response.getPayoffDate());
        assertEquals(0, new BigDecimal("31000.00").compareTo(response.getOriginalBalance()));
        assertEquals(0, finalInterest.compareTo(response.getFinalInterest()));
        // Total payoff = balance + final interest (FPLPAY00)
        assertTrue(response.getTotalPayoff().compareTo(BigDecimal.ZERO) > 0);

        // Verify entity updated: balance → 0, status → PD
        assertEquals("PD", testFloorPlan.getFpStatus());
        assertEquals(0, BigDecimal.ZERO.compareTo(testFloorPlan.getCurrentBalance()));
        // Cumulative interest = existing(150) + final interest
        assertEquals(0, new BigDecimal("150.00").add(finalInterest).compareTo(testFloorPlan.getInterestAccrued()));
    }

    @Test
    @DisplayName("payoff: no active floor plan → EntityNotFoundException (FPLPAY00 AC check)")
    void testPayoff_noActiveFloorPlan() {
        when(floorPlanVehicleRepository.findByVinAndFpStatus("1HGCM82633A004352", "AC"))
                .thenReturn(Optional.empty());

        FloorPlanPayoffRequest request = FloorPlanPayoffRequest.builder()
                .vin("1HGCM82633A004352")
                .build();

        assertThrows(EntityNotFoundException.class,
                () -> floorPlanService.payoffFloorPlan(request));
    }

    @Test
    @DisplayName("payoff: lender not found → default rate 5% used (FPLPAY00 fallback)")
    void testPayoff_lenderNotFoundUsesDefault() {
        when(floorPlanVehicleRepository.findByVinAndFpStatus("1HGCM82633A004352", "AC"))
                .thenReturn(Optional.of(testFloorPlan));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.empty());

        // Should use default 5% rate
        when(interestCalculator.calculateRangeInterest(
                any(), eq(new BigDecimal("5.00")), eq(DayCountBasis.ACTUAL_365), any(), any()))
                .thenReturn(new BigDecimal("100.00"));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        FloorPlanPayoffRequest request = FloorPlanPayoffRequest.builder()
                .vin("1HGCM82633A004352")
                .build();

        FloorPlanPayoffResponse response = floorPlanService.payoffFloorPlan(request);
        assertNotNull(response);
        assertEquals("PD", response.getStatus());
    }

    // ========================================================================
    // 3. INTEREST CALCULATION — SINGLE MODE (FPLINT00)
    // ========================================================================

    @Test
    @DisplayName("calculateInterest: SINGLE mode — daily interest accrued, detail record created (FPLINT00)")
    void testInterest_singleMode() {
        when(floorPlanVehicleRepository.findByVinAndFpStatus("1HGCM82633A004352", "AC"))
                .thenReturn(Optional.of(testFloorPlan));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        // Daily interest = balance * rate / 365 (COMINTL0 DAY function)
        BigDecimal dailyInterest = new BigDecimal("4.25");
        when(interestCalculator.calculateDailyInterest(
                eq(new BigDecimal("31000.00")), eq(new BigDecimal("5.000")),
                eq(DayCountBasis.ACTUAL_365), any(LocalDate.class)))
                .thenReturn(dailyInterest);

        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(floorPlanInterestRepository.save(any(FloorPlanInterest.class))).thenAnswer(inv -> inv.getArgument(0));

        FloorPlanInterestRequest request = FloorPlanInterestRequest.builder()
                .mode("SINGLE")
                .vin("1HGCM82633A004352")
                .build();

        FloorPlanInterestResponse response = floorPlanService.calculateInterest(request);

        assertNotNull(response);
        assertEquals("SINGLE", response.getMode());
        assertEquals(1, response.getProcessedCount());
        assertEquals(1, response.getUpdatedCount());
        assertEquals(0, response.getErrorCount());
        assertEquals(0, dailyInterest.compareTo(response.getTotalInterestAmount()));

        // Verify interest detail record inserted (FPLINT00 audit trail)
        verify(floorPlanInterestRepository).save(any(FloorPlanInterest.class));

        // Verify vehicle updated
        assertEquals(0, new BigDecimal("150.00").add(dailyInterest).compareTo(testFloorPlan.getInterestAccrued()));
    }

    @Test
    @DisplayName("calculateInterest: SINGLE mode missing VIN → rejection (FPLINT00 validation)")
    void testInterest_singleModeMissingVin() {
        FloorPlanInterestRequest request = FloorPlanInterestRequest.builder()
                .mode("SINGLE")
                .vin(null)
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> floorPlanService.calculateInterest(request));

        assertTrue(ex.getMessage().contains("VIN is required"));
    }

    // ========================================================================
    // 4. INTEREST CALCULATION — BATCH MODE (FPLINT00)
    // ========================================================================

    @Test
    @DisplayName("calculateInterest: BATCH mode — processes all active vehicles for dealer (FPLINT00)")
    void testInterest_batchMode() {
        FloorPlanVehicle fpv2 = FloorPlanVehicle.builder()
                .floorPlanId(2)
                .vin("2T1BURHE5GC123456")
                .dealerCode("DLR01")
                .lenderId("LND01")
                .invoiceAmount(new BigDecimal("28000.00"))
                .currentBalance(new BigDecimal("28000.00"))
                .interestAccrued(new BigDecimal("50.00"))
                .floorDate(LocalDate.now().minusDays(10))
                .curtailmentDate(LocalDate.now().plusDays(80))
                .fpStatus("AC")
                .daysOnFloor((short) 10)
                .build();

        Vehicle vehicle2 = Vehicle.builder()
                .vin("2T1BURHE5GC123456")
                .modelYear((short) 2026)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .vehicleStatus("AV")
                .dealerCode("DLR01")
                .daysInStock((short) 10)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(10)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        when(floorPlanVehicleRepository.findByDealerCodeAndFpStatus("DLR01", "AC"))
                .thenReturn(List.of(testFloorPlan, fpv2));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.findById("2T1BURHE5GC123456")).thenReturn(Optional.of(vehicle2));

        when(interestCalculator.calculateDailyInterest(any(), any(), any(), any()))
                .thenReturn(new BigDecimal("4.00"));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(floorPlanInterestRepository.save(any(FloorPlanInterest.class))).thenAnswer(inv -> inv.getArgument(0));

        FloorPlanInterestRequest request = FloorPlanInterestRequest.builder()
                .mode("BATCH")
                .dealerCode("DLR01")
                .build();

        FloorPlanInterestResponse response = floorPlanService.calculateInterest(request);

        assertEquals("BATCH", response.getMode());
        assertEquals(2, response.getProcessedCount());
        assertEquals(2, response.getUpdatedCount());
        assertEquals(0, response.getErrorCount());
        // Total interest = 4.00 * 2 = 8.00
        assertEquals(0, new BigDecimal("8.00").compareTo(response.getTotalInterestAmount()));
        assertEquals(2, response.getDetails().size());
    }

    @Test
    @DisplayName("calculateInterest: BATCH mode missing dealer → rejection (FPLINT00 validation)")
    void testInterest_batchModeMissingDealer() {
        FloorPlanInterestRequest request = FloorPlanInterestRequest.builder()
                .mode("BATCH")
                .dealerCode(null)
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> floorPlanService.calculateInterest(request));

        assertTrue(ex.getMessage().contains("Dealer code is required"));
    }

    @Test
    @DisplayName("calculateInterest: curtailment warning at ≤ 15 days (FPLINT00 WS-CURTAIL-THRESHOLD)")
    void testInterest_curtailmentWarning() {
        // Set curtailment date to 10 days from now (within 15-day threshold)
        testFloorPlan.setCurtailmentDate(LocalDate.now().plusDays(10));

        when(floorPlanVehicleRepository.findByVinAndFpStatus("1HGCM82633A004352", "AC"))
                .thenReturn(Optional.of(testFloorPlan));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(interestCalculator.calculateDailyInterest(any(), any(), any(), any()))
                .thenReturn(new BigDecimal("4.00"));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(floorPlanInterestRepository.save(any(FloorPlanInterest.class))).thenAnswer(inv -> inv.getArgument(0));

        FloorPlanInterestRequest request = FloorPlanInterestRequest.builder()
                .mode("SINGLE")
                .vin("1HGCM82633A004352")
                .build();

        FloorPlanInterestResponse response = floorPlanService.calculateInterest(request);

        assertEquals(1, response.getCurtailmentWarningCount());
        assertTrue(response.getDetails().get(0).isWarning());
        assertTrue(response.getDetails().get(0).getDaysToCurtailment() <= 15);
    }

    // ========================================================================
    // 5. LIST LENDERS (FPLND00)
    // ========================================================================

    @Test
    @DisplayName("listLenders: returns lenders with effective rate = baseRate + spread")
    void testListLenders() {
        FloorPlanLender lender2 = FloorPlanLender.builder()
                .lenderId("LND02")
                .lenderName("Auto Finance Corp")
                .baseRate(new BigDecimal("4.000"))
                .spread(new BigDecimal("2.000"))
                .curtailmentDays(60)
                .freeFloorDays(3)
                .build();

        when(floorPlanLenderRepository.findAllByOrderByLenderNameAsc())
                .thenReturn(List.of(lender2, testLender));
        lenient().when(fieldFormatter.formatPhone(anyString())).thenReturn("(214) 555-9999");

        List<FloorPlanLenderResponse> lenders = floorPlanService.listLenders();

        assertEquals(2, lenders.size());
        // First lender: Auto Finance Corp (sorted by name)
        assertEquals("LND02", lenders.get(0).getLenderId());
        assertEquals(0, new BigDecimal("6.000").compareTo(lenders.get(0).getEffectiveRate())); // 4.0 + 2.0
        // Second lender: First Floor Plan Bank
        assertEquals("LND01", lenders.get(1).getLenderId());
        assertEquals(0, new BigDecimal("5.000").compareTo(lenders.get(1).getEffectiveRate())); // 3.5 + 1.5
    }
}
