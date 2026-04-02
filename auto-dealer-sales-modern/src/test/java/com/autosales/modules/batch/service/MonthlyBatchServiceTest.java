package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.dto.MonthlySnapshotResponse;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.entity.MonthlySnapshot;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.batch.repository.MonthlySnapshotRepository;
import com.autosales.modules.admin.entity.Dealer;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.finance.entity.FinanceProduct;
import com.autosales.modules.finance.repository.FinanceProductRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockPositionRepository;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for MonthlyBatchService — port of BATMTH00.cbl.
 * Validates:
 *   Phase 1: Monthly snapshot KPI calculations (units, revenue, gross, F&I per deal, avg days to sell)
 *   Phase 2: SOLD_MTD counter rollover to zero
 *   Phase 3: Deal archival after 18 months
 */
@ExtendWith(MockitoExtension.class)
class MonthlyBatchServiceTest {

    @Mock private MonthlySnapshotRepository monthlySnapshotRepository;
    @Mock private BatchControlRepository batchControlRepository;
    @Mock private DealerRepository dealerRepository;
    @Mock private SalesDealRepository salesDealRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private StockPositionRepository stockPositionRepository;
    @Mock private FinanceProductRepository financeProductRepository;

    @InjectMocks
    private MonthlyBatchService monthlyBatchService;

    private Dealer testDealer;
    private SalesDeal deliveredDeal1;
    private SalesDeal deliveredDeal2;
    private Vehicle testVehicle;
    private StockPosition testStockPosition;

    @BeforeEach
    void setUp() {
        testDealer = Dealer.builder()
                .dealerCode("D0001")
                .dealerName("Test Motors")
                .activeFlag("Y")
                .build();

        deliveredDeal1 = SalesDeal.builder()
                .dealNumber("DL-100")
                .dealerCode("D0001")
                .dealStatus("DL")
                .vin("1HGCM82633A004352")
                .totalPrice(new BigDecimal("45000.00"))
                .totalGross(new BigDecimal("3500.00"))
                .dealDate(LocalDate.now().withDayOfMonth(5))
                .deliveryDate(LocalDate.now().withDayOfMonth(10))
                .build();

        deliveredDeal2 = SalesDeal.builder()
                .dealNumber("DL-101")
                .dealerCode("D0001")
                .dealStatus("DL")
                .vin("2T1BURHE0JC123456")
                .totalPrice(new BigDecimal("38000.00"))
                .totalGross(new BigDecimal("2800.00"))
                .dealDate(LocalDate.now().withDayOfMonth(12))
                .deliveryDate(LocalDate.now().withDayOfMonth(15))
                .build();

        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .receiveDate(LocalDate.now().minusDays(30))
                .build();

        testStockPosition = StockPosition.builder()
                .dealerCode("D0001")
                .modelYear((short) 2026)
                .makeCode("HON")
                .modelCode("ACCORD")
                .soldMtd((short) 5)
                .soldYtd((short) 45)
                .onHandCount((short) 10)
                .inTransitCount((short) 3)
                .allocatedCount((short) 2)
                .onHoldCount((short) 1)
                .reorderPoint((short) 5)
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ── Phase 1: Monthly Snapshot Calculations ────────────────────────

    @Test
    @DisplayName("BATMTH00 Phase 1: Snapshot calculates F&I per deal = F&I gross / units sold")
    void calculateMonthlySnapshots_fiPerDealFormula() {
        when(dealerRepository.findByActiveFlagOrderByDealerName("Y")).thenReturn(List.of(testDealer));
        when(salesDealRepository.findByDealerCodeAndDealDateBetween(eq("D0001"), any(), any()))
                .thenReturn(List.of(deliveredDeal1, deliveredDeal2));

        // F&I products: deal1=$1200, deal2=$800 → total F&I=$2000
        FinanceProduct fp1 = FinanceProduct.builder().dealNumber("DL-100").grossProfit(new BigDecimal("1200.00")).build();
        FinanceProduct fp2 = FinanceProduct.builder().dealNumber("DL-101").grossProfit(new BigDecimal("800.00")).build();
        when(financeProductRepository.findByDealNumber("DL-100")).thenReturn(List.of(fp1));
        when(financeProductRepository.findByDealNumber("DL-101")).thenReturn(List.of(fp2));

        Vehicle v1 = Vehicle.builder().vin("1HGCM82633A004352").receiveDate(LocalDate.now().minusDays(30)).build();
        Vehicle v2 = Vehicle.builder().vin("2T1BURHE0JC123456").receiveDate(LocalDate.now().minusDays(20)).build();
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(v1));
        when(vehicleRepository.findById("2T1BURHE0JC123456")).thenReturn(Optional.of(v2));

        when(monthlySnapshotRepository.findById(any())).thenReturn(Optional.empty());
        when(monthlySnapshotRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        List<String> warnings = new ArrayList<>();
        int count = monthlyBatchService.calculateMonthlySnapshots(
                LocalDate.now().toString().substring(0, 7).replace("-", ""), warnings);

        assertEquals(1, count);

        ArgumentCaptor<MonthlySnapshot> captor = ArgumentCaptor.forClass(MonthlySnapshot.class);
        verify(monthlySnapshotRepository).save(captor.capture());
        MonthlySnapshot snapshot = captor.getValue();

        assertEquals((short) 2, snapshot.getTotalUnitsSold());
        assertEquals(new BigDecimal("83000.00"), snapshot.getTotalRevenue(),
                "BATMTH00: Total revenue = sum of total_price for delivered deals");
        assertEquals(new BigDecimal("6300.00"), snapshot.getTotalGross(),
                "BATMTH00: Total gross = sum of total_gross for delivered deals");
        assertEquals(new BigDecimal("2000.00"), snapshot.getTotalFiGross(),
                "BATMTH00: F&I gross = sum of finance_product gross_profit");
        assertEquals(new BigDecimal("1000.00"), snapshot.getFiPerDeal(),
                "BATMTH00: F&I per deal = F&I gross / units sold");
        assertEquals("Y", snapshot.getFrozenFlag(),
                "BATMTH00: Frozen flag must be set to Y");
    }

    @Test
    @DisplayName("BATMTH00 Phase 1: Dealer with no sales is skipped")
    void calculateMonthlySnapshots_noSalesSkipped() {
        when(dealerRepository.findByActiveFlagOrderByDealerName("Y")).thenReturn(List.of(testDealer));
        when(salesDealRepository.findByDealerCodeAndDealDateBetween(eq("D0001"), any(), any()))
                .thenReturn(List.of());

        List<String> warnings = new ArrayList<>();
        int count = monthlyBatchService.calculateMonthlySnapshots("202603", warnings);

        assertEquals(0, count);
        verify(monthlySnapshotRepository, never()).save(any());
    }

    // ── Phase 2: Roll Monthly Counters ────────────────────────────────

    @Test
    @DisplayName("BATMTH00 Phase 2: SOLD_MTD is reset to zero on all stock positions")
    void rollMonthlyCounters_resetsSoldMtd() {
        when(stockPositionRepository.findAll()).thenReturn(List.of(testStockPosition));
        when(stockPositionRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        int count = monthlyBatchService.rollMonthlyCounters();

        assertEquals(1, count);
        ArgumentCaptor<StockPosition> captor = ArgumentCaptor.forClass(StockPosition.class);
        verify(stockPositionRepository).save(captor.capture());
        assertEquals((short) 0, captor.getValue().getSoldMtd(),
                "BATMTH00: SOLD_MTD must be reset to 0");
        assertEquals((short) 45, captor.getValue().getSoldYtd(),
                "BATMTH00: SOLD_YTD must NOT be affected by monthly roll");
    }

    // ── Phase 3: Archive Old Deals ────────────────────────────────────

    @Test
    @DisplayName("BATMTH00 Phase 3: Completed deals older than 18 months archived to AR status")
    void archiveOldDeals_archivesDeliveredDeals() {
        SalesDeal oldDeal = SalesDeal.builder()
                .dealNumber("DL-OLD")
                .dealStatus("DL")
                .deliveryDate(LocalDate.now().minusMonths(20)) // 20 months old
                .updatedTs(LocalDateTime.now())
                .build();
        when(salesDealRepository.findAll()).thenReturn(List.of(oldDeal));
        when(salesDealRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        int count = monthlyBatchService.archiveOldDeals();

        assertEquals(1, count);
        ArgumentCaptor<SalesDeal> captor = ArgumentCaptor.forClass(SalesDeal.class);
        verify(salesDealRepository).save(captor.capture());
        assertEquals("AR", captor.getValue().getDealStatus(),
                "BATMTH00: Deal delivered >18 months ago must be archived (AR)");
    }

    @Test
    @DisplayName("BATMTH00 Phase 3: Deal within 18 months is not archived")
    void archiveOldDeals_recentDealNotArchived() {
        SalesDeal recentDeal = SalesDeal.builder()
                .dealNumber("DL-REC")
                .dealStatus("DL")
                .deliveryDate(LocalDate.now().minusMonths(6))
                .build();
        when(salesDealRepository.findAll()).thenReturn(List.of(recentDeal));

        int count = monthlyBatchService.archiveOldDeals();

        assertEquals(0, count);
    }

    // ── Full Run ──────────────────────────────────────────────────────

    @Test
    @DisplayName("BATMTH00: Full monthly close returns three phases")
    void runMonthlyClose_completesWithThreePhases() {
        when(dealerRepository.findByActiveFlagOrderByDealerName("Y")).thenReturn(List.of());
        when(stockPositionRepository.findAll()).thenReturn(List.of());
        when(salesDealRepository.findAll()).thenReturn(List.of());
        when(batchControlRepository.findById("BATMTH00")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        BatchRunResult result = monthlyBatchService.runMonthlyClose();

        assertEquals("BATMTH00", result.getProgramId());
        assertEquals("OK", result.getStatus());
        assertEquals(3, result.getPhases().size());
    }

    // ── Query Methods ─────────────────────────────────────────────────

    @Test
    @DisplayName("BATMTH00: getSnapshotsByDealer maps entity correctly")
    void getSnapshotsByDealer_mapsCorrectly() {
        MonthlySnapshot snapshot = MonthlySnapshot.builder()
                .snapshotMonth("202603")
                .dealerCode("D0001")
                .totalUnitsSold((short) 25)
                .totalRevenue(new BigDecimal("875000.00"))
                .totalGross(new BigDecimal("62500.00"))
                .totalFiGross(new BigDecimal("25000.00"))
                .avgDaysToSell((short) 28)
                .inventoryTurn(new BigDecimal("2.50"))
                .fiPerDeal(new BigDecimal("1000.00"))
                .frozenFlag("Y")
                .createdTs(LocalDateTime.now())
                .build();
        when(monthlySnapshotRepository.findByDealerCodeOrderBySnapshotMonthDesc("D0001"))
                .thenReturn(List.of(snapshot));

        List<MonthlySnapshotResponse> result = monthlyBatchService.getSnapshotsByDealer("D0001");

        assertEquals(1, result.size());
        assertEquals(new BigDecimal("1000.00"), result.get(0).getFiPerDeal());
    }
}
