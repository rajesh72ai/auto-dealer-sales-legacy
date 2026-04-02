package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.DailySalesSummaryResponse;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.entity.DailySalesSummary;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for DailyBatchService — port of BATDLY00.cbl.
 * Validates the three-phase nightly batch:
 *   Phase 1: Delivered vehicles marked SOLD
 *   Phase 2: Pending deals expired after 30 days
 *   Phase 3: Floor plan interest accrual using legacy formula
 */
@ExtendWith(MockitoExtension.class)
class DailyBatchServiceTest {

    @Mock private DailySalesSummaryRepository dailySalesSummaryRepository;
    @Mock private BatchControlRepository batchControlRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private FloorPlanVehicleRepository floorPlanVehicleRepository;
    @Mock private FloorPlanLenderRepository floorPlanLenderRepository;
    @Mock private FloorPlanInterestRepository floorPlanInterestRepository;

    @InjectMocks
    private DailyBatchService dailyBatchService;

    private Vehicle testVehicle;
    private SalesDeal deliveredDeal;
    private SalesDeal pendingDeal;
    private FloorPlanVehicle testFpv;
    private FloorPlanLender testLender;

    @BeforeEach
    void setUp() {
        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .vehicleStatus("AV")
                .dealerCode("D0001")
                .updatedTs(LocalDateTime.now())
                .build();

        deliveredDeal = SalesDeal.builder()
                .dealNumber("DL-001")
                .vin("1HGCM82633A004352")
                .dealerCode("D0001")
                .dealStatus("DL")
                .dealDate(LocalDate.now())
                .updatedTs(LocalDateTime.now())
                .build();

        pendingDeal = SalesDeal.builder()
                .dealNumber("DL-002")
                .dealerCode("D0001")
                .dealStatus("WS")
                .dealDate(LocalDate.now().minusDays(45)) // 45 days old — should expire
                .updatedTs(LocalDateTime.now())
                .build();

        testFpv = FloorPlanVehicle.builder()
                .floorPlanId(1)
                .vin("2T1BURHE0JC123456")
                .dealerCode("D0001")
                .lenderId("LND01")
                .currentBalance(new BigDecimal("35000.00"))
                .interestAccrued(new BigDecimal("150.00"))
                .fpStatus("AC")
                .daysOnFloor((short) 30)
                .lastInterestDt(LocalDate.now().minusDays(1))
                .build();

        testLender = FloorPlanLender.builder()
                .lenderId("LND01")
                .lenderName("Test Lender")
                .baseRate(new BigDecimal("5.50"))
                .spread(new BigDecimal("1.25"))
                .curtailmentDays(90)
                .freeFloorDays(0)
                .build();
    }

    // ── Phase 1: Delivered Vehicles → SOLD ────────────────────────────

    @Test
    @DisplayName("BATDLY00 Phase 1: Delivered vehicle with DL deal gets status changed to SD")
    void processDeliveredVehicles_marksVehicleSold() {
        when(vehicleRepository.findAll()).thenReturn(List.of(testVehicle));
        when(salesDealRepository.findByVin("1HGCM82633A004352")).thenReturn(Optional.of(deliveredDeal));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(i -> i.getArgument(0));

        int count = dailyBatchService.processDeliveredVehicles();

        assertEquals(1, count);
        ArgumentCaptor<Vehicle> captor = ArgumentCaptor.forClass(Vehicle.class);
        verify(vehicleRepository).save(captor.capture());
        assertEquals("SD", captor.getValue().getVehicleStatus());
    }

    @Test
    @DisplayName("BATDLY00 Phase 1: Vehicle without delivered deal is not changed")
    void processDeliveredVehicles_noDeliveredDeal_skipped() {
        SalesDeal wsDeal = SalesDeal.builder().dealNumber("DL-003").dealStatus("WS").build();
        when(vehicleRepository.findAll()).thenReturn(List.of(testVehicle));
        when(salesDealRepository.findByVin("1HGCM82633A004352")).thenReturn(Optional.of(wsDeal));

        int count = dailyBatchService.processDeliveredVehicles();

        assertEquals(0, count);
        verify(vehicleRepository, never()).save(any());
    }

    // ── Phase 2: Expire Pending Deals ─────────────────────────────────

    @Test
    @DisplayName("BATDLY00 Phase 2: Pending deal older than 30 days expires to CA status")
    void expirePendingDeals_expiresOldDeals() {
        when(salesDealRepository.findAll()).thenReturn(List.of(pendingDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(i -> i.getArgument(0));

        int count = dailyBatchService.expirePendingDeals();

        assertEquals(1, count);
        ArgumentCaptor<SalesDeal> captor = ArgumentCaptor.forClass(SalesDeal.class);
        verify(salesDealRepository).save(captor.capture());
        assertEquals("CA", captor.getValue().getDealStatus(),
                "BATDLY00: Pending deal >30 days must be cancelled (CA)");
    }

    @Test
    @DisplayName("BATDLY00 Phase 2: Recent pending deal within 30 days is not expired")
    void expirePendingDeals_recentDealNotExpired() {
        SalesDeal recentDeal = SalesDeal.builder()
                .dealNumber("DL-004")
                .dealStatus("WS")
                .dealDate(LocalDate.now().minusDays(10)) // Only 10 days old
                .build();
        when(salesDealRepository.findAll()).thenReturn(List.of(recentDeal));

        int count = dailyBatchService.expirePendingDeals();

        assertEquals(0, count);
        verify(salesDealRepository, never()).save(any());
    }

    @Test
    @DisplayName("BATDLY00 Phase 2: NE and PA statuses also eligible for expiry")
    void expirePendingDeals_allPendingStatusesEligible() {
        SalesDeal neDeal = SalesDeal.builder()
                .dealNumber("DL-NE1").dealStatus("NE").dealDate(LocalDate.now().minusDays(35)).build();
        SalesDeal paDeal = SalesDeal.builder()
                .dealNumber("DL-PA1").dealStatus("PA").dealDate(LocalDate.now().minusDays(40)).build();
        when(salesDealRepository.findAll()).thenReturn(List.of(neDeal, paDeal));
        when(salesDealRepository.save(any(SalesDeal.class))).thenAnswer(i -> i.getArgument(0));

        int count = dailyBatchService.expirePendingDeals();

        assertEquals(2, count, "Both NE and PA deals older than 30 days should expire");
    }

    // ── Phase 3: Floor Plan Interest Accrual ──────────────────────────

    @Test
    @DisplayName("BATDLY00 Phase 3: Interest formula — BALANCE * (BASE+SPREAD) / 365 / 100")
    void accrueFloorPlanInterest_calculatesCorrectly() {
        when(floorPlanVehicleRepository.findByFpStatus("AC")).thenReturn(List.of(testFpv));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.of(testLender));
        when(floorPlanInterestRepository.save(any(FloorPlanInterest.class))).thenAnswer(i -> i.getArgument(0));
        when(floorPlanVehicleRepository.save(any(FloorPlanVehicle.class))).thenAnswer(i -> i.getArgument(0));

        java.util.List<String> warnings = new java.util.ArrayList<>();
        int count = dailyBatchService.accrueFloorPlanInterest(warnings);

        assertEquals(1, count);
        assertEquals(0, warnings.size());

        // Verify the exact interest formula from BATDLY00 CALC-INTEREST paragraph:
        // COMBINED_RATE = 5.50 + 1.25 = 6.75
        // DAILY_RATE = 6.75 / 365 = 0.0184931507...
        // DAILY_INTEREST = 35000.00 * 0.0184931507... / 100 = 6.47
        BigDecimal expectedCombinedRate = new BigDecimal("6.75");
        BigDecimal expectedDailyRate = expectedCombinedRate.divide(BigDecimal.valueOf(365), 10, RoundingMode.HALF_UP);
        BigDecimal expectedDailyInterest = new BigDecimal("35000.00")
                .multiply(expectedDailyRate)
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal expectedCumulative = new BigDecimal("150.00").add(expectedDailyInterest);

        ArgumentCaptor<FloorPlanInterest> intCaptor = ArgumentCaptor.forClass(FloorPlanInterest.class);
        verify(floorPlanInterestRepository).save(intCaptor.capture());
        FloorPlanInterest savedInterest = intCaptor.getValue();

        assertEquals(expectedCombinedRate, savedInterest.getRateApplied(),
                "BATDLY00: COMBINED_RATE must be BASE_RATE + SPREAD");
        assertEquals(expectedDailyInterest, savedInterest.getDailyInterest(),
                "BATDLY00: DAILY_INTEREST = BALANCE * (BASE+SPREAD) / 365 / 100");
        assertEquals(expectedCumulative, savedInterest.getCumulativeInt(),
                "BATDLY00: CUMULATIVE = prior accrued + daily interest");

        ArgumentCaptor<FloorPlanVehicle> fpvCaptor = ArgumentCaptor.forClass(FloorPlanVehicle.class);
        verify(floorPlanVehicleRepository).save(fpvCaptor.capture());
        assertEquals(expectedCumulative, fpvCaptor.getValue().getInterestAccrued());
        assertEquals((short) 31, fpvCaptor.getValue().getDaysOnFloor(),
                "BATDLY00: Days on floor incremented by 1");
    }

    @Test
    @DisplayName("BATDLY00 Phase 3: Missing lender adds warning and skips vehicle")
    void accrueFloorPlanInterest_missingLender_addsWarning() {
        when(floorPlanVehicleRepository.findByFpStatus("AC")).thenReturn(List.of(testFpv));
        when(floorPlanLenderRepository.findByLenderId("LND01")).thenReturn(Optional.empty());

        java.util.List<String> warnings = new java.util.ArrayList<>();
        int count = dailyBatchService.accrueFloorPlanInterest(warnings);

        assertEquals(0, count);
        assertEquals(1, warnings.size());
        assertTrue(warnings.get(0).contains("No lender found"));
    }

    // ── Full Run ──────────────────────────────────────────────────────

    @Test
    @DisplayName("BATDLY00: Full daily run returns OK status with phase details")
    void runDailyEndOfDay_completesSuccessfully() {
        when(vehicleRepository.findAll()).thenReturn(List.of());
        when(salesDealRepository.findAll()).thenReturn(List.of());
        when(floorPlanVehicleRepository.findByFpStatus("AC")).thenReturn(List.of());
        when(batchControlRepository.findById("BATDLY00")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        BatchRunResult result = dailyBatchService.runDailyEndOfDay();

        assertEquals("BATDLY00", result.getProgramId());
        assertEquals("OK", result.getStatus());
        assertEquals(3, result.getPhases().size());
        assertNotNull(result.getStartedAt());
        assertNotNull(result.getCompletedAt());
    }

    // ── Query Methods ─────────────────────────────────────────────────

    @Test
    @DisplayName("BATDLY00: getDailySummaries maps entity to response correctly")
    void getDailySummaries_mapsCorrectly() {
        DailySalesSummary summary = DailySalesSummary.builder()
                .summaryDate(LocalDate.of(2026, 3, 15))
                .dealerCode("D0001")
                .modelYear((short) 2026)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .unitsSold((short) 5)
                .totalRevenue(new BigDecimal("175000.00"))
                .totalGross(new BigDecimal("12500.00"))
                .frontGross(new BigDecimal("8000.00"))
                .backGross(new BigDecimal("4500.00"))
                .avgSellingPrice(new BigDecimal("35000.00"))
                .avgGrossPerUnit(new BigDecimal("2500.00"))
                .build();

        when(dailySalesSummaryRepository.findByDealerCodeAndSummaryDateBetweenOrderBySummaryDateDesc(
                eq("D0001"), any(), any())).thenReturn(List.of(summary));

        List<DailySalesSummaryResponse> result = dailyBatchService.getDailySummaries(
                "D0001", LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31));

        assertEquals(1, result.size());
        assertEquals("D0001", result.get(0).getDealerCode());
        assertEquals(new BigDecimal("175000.00"), result.get(0).getTotalRevenue());
        assertEquals(new BigDecimal("2500.00"), result.get(0).getAvgGrossPerUnit());
    }
}
