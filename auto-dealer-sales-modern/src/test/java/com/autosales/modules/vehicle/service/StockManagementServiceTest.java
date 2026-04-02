package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
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
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for StockManagementService — stock positions, adjustments, alerts, reconciliation, valuation.
 * Port of STKINQ00, STKSUM00, STKADJT0, STKALRT0, STKHLD00, STKRCN00, STKVALS0.
 */
@ExtendWith(MockitoExtension.class)
class StockManagementServiceTest {

    @Mock private StockPositionRepository stockPositionRepository;
    @Mock private StockAdjustmentRepository stockAdjustmentRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private StockPositionService stockPositionService;
    @Mock private PriceMasterRepository priceMasterRepository;
    @Mock private ModelMasterRepository modelMasterRepository;
    @Mock private DealerRepository dealerRepository;

    @InjectMocks
    private StockManagementService stockManagementService;

    // Common test fixtures
    private StockPosition testPosition;
    private Vehicle testVehicle;

    @BeforeEach
    void setUp() {
        testPosition = StockPosition.builder()
                .dealerCode("D0001")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .onHandCount((short) 8)
                .inTransitCount((short) 3)
                .allocatedCount((short) 2)
                .onHoldCount((short) 1)
                .soldMtd((short) 5)
                .soldYtd((short) 45)
                .reorderPoint((short) 10)
                .updatedTs(LocalDateTime.now())
                .build();

        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .exteriorColor("White")
                .interiorColor("Black")
                .vehicleStatus("AV")
                .dealerCode("D0001")
                .daysInStock((short) 20)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(15)
                .receiveDate(LocalDate.now().minusDays(20))
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ── STKINQ00: getPositions ──────────────────────────────────────────

    @Test
    @DisplayName("STKINQ00: getPositions returns positions with low stock alert flag")
    void getPositions_returnsWithLowStockAlert() {
        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(testPosition));
        when(modelMasterRepository.findById(any(ModelMasterId.class))).thenReturn(Optional.empty());

        List<StockPositionResponse> result = stockManagementService.getPositions("D0001");

        assertEquals(1, result.size());
        StockPositionResponse resp = result.get(0);
        assertEquals((short) 8, resp.getOnHandCount());
        assertEquals((short) 10, resp.getReorderPoint());
        assertTrue(resp.isLowStockAlert()); // 8 < 10
    }

    // ── STKSUM00: getSummary ────────────────────────────────────────────

    @Test
    @DisplayName("STKSUM00: getSummary returns aggregate counts and value")
    void getSummary_returnsAggregateCounts() {
        when(dealerRepository.findById("D0001"))
                .thenReturn(Optional.of(Dealer.builder().dealerCode("D0001").dealerName("Test Dealer").build()));
        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(testPosition));
        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.of(PriceMaster.builder().invoicePrice(new BigDecimal("30000.00")).build()));
        when(vehicleRepository.findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                eq("D0001"), eq(List.of("AV", "HD", "AL"))))
                .thenReturn(List.of(testVehicle));

        StockSummaryResponse result = stockManagementService.getSummary("D0001");

        assertEquals("D0001", result.getDealerCode());
        assertEquals("Test Dealer", result.getDealerName());
        assertEquals(8, result.getTotalOnHand());
        assertEquals(3, result.getTotalInTransit());
        assertEquals(2, result.getTotalAllocated());
        assertEquals(1, result.getTotalOnHold());
        // totalValue = 30000 * 8 on-hand
        assertEquals(new BigDecimal("240000.00"), result.getTotalValue());
    }

    // ── STKADJT0: createAdjustment ──────────────────────────────────────

    @Test
    @DisplayName("STKADJT0: createAdjustment DM type — damage flag set, status unchanged")
    void createAdjustment_DM_setsDemageFlagNoStatusChange() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(stockAdjustmentRepository.save(any(StockAdjustment.class))).thenAnswer(inv -> {
            StockAdjustment adj = inv.getArgument(0);
            adj.setAdjustId(1);
            return adj;
        });

        StockAdjustmentRequest request = StockAdjustmentRequest.builder()
                .dealerCode("D0001").vin("1HGCM82633A004352")
                .adjustType("DM").adjustReason("Hail damage").adjustedBy("MGR01")
                .build();

        StockAdjustmentResponse result = stockManagementService.createAdjustment(request);

        assertEquals("DM", result.getAdjustType());
        assertEquals("Damage", result.getAdjustTypeName());
        assertEquals("AV", result.getOldStatus());
        assertEquals("AV", result.getNewStatus()); // DM does not change status
        verify(vehicleRepository).save(argThat(v -> "Y".equals(v.getDamageFlag())));
        verify(stockPositionService).processSold(eq("1HGCM82633A004352"), eq("D0001"),
                eq("MGR01"), anyString());
    }

    @Test
    @DisplayName("STKADJT0: createAdjustment PH type — no status change")
    void createAdjustment_PH_noStatusChange() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(stockAdjustmentRepository.save(any(StockAdjustment.class))).thenAnswer(inv -> {
            StockAdjustment adj = inv.getArgument(0);
            adj.setAdjustId(2);
            return adj;
        });

        StockAdjustmentRequest request = StockAdjustmentRequest.builder()
                .dealerCode("D0001").vin("1HGCM82633A004352")
                .adjustType("PH").adjustReason("Physical count adjustment").adjustedBy("MGR01")
                .build();

        StockAdjustmentResponse result = stockManagementService.createAdjustment(request);

        assertEquals("PH", result.getAdjustType());
        assertEquals("AV", result.getOldStatus());
        assertEquals("AV", result.getNewStatus());
        verify(vehicleRepository, never()).save(any()); // PH does not modify vehicle
        verify(stockPositionService, never()).processSold(any(), any(), any(), any());
    }

    @Test
    @DisplayName("STKADJT0: createAdjustment invalid type rejects")
    void createAdjustment_invalidType_throwsException() {
        StockAdjustmentRequest request = StockAdjustmentRequest.builder()
                .dealerCode("D0001").vin("1HGCM82633A004352")
                .adjustType("XX").adjustReason("Bad type").adjustedBy("MGR01")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> stockManagementService.createAdjustment(request));
        assertTrue(ex.getMessage().contains("Invalid adjustment type"));
    }

    // ── STKALRT0: getAlerts ─────────────────────────────────────────────

    @Test
    @DisplayName("STKALRT0: getAlerts returns deficit + safety stock (2) as suggested order")
    void getAlerts_returnsDeficitPlusSafetyStock() {
        // onHandCount=8, reorderPoint=10 → deficit=2, suggested=4 (2+2 safety)
        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(testPosition));
        when(modelMasterRepository.findById(any(ModelMasterId.class))).thenReturn(Optional.empty());

        List<StockAlertResponse> result = stockManagementService.getAlerts("D0001");

        assertEquals(1, result.size());
        StockAlertResponse alert = result.get(0);
        assertEquals("LOW_STOCK", alert.getAlertType());
        assertEquals(8, alert.getCurrentCount());
        assertEquals(10, alert.getReorderPoint());
        assertEquals(2, alert.getDeficit());
        assertEquals(4, alert.getSuggestedOrder()); // deficit(2) + safety(2) = 4
    }

    // ── STKHLD00: holdVehicle ───────────────────────────────────────────

    @Test
    @DisplayName("STKHLD00: holdVehicle delegates to StockPositionService, requires AV status")
    void holdVehicle_delegatesAndRequiresAV() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        StockUpdateResult expectedResult = new StockUpdateResult(
                "1HGCM82633A004352", "AV", "HD", "D0001", true, "Vehicle placed on hold");
        when(stockPositionService.processHold(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(expectedResult);

        StockHoldRequest request = StockHoldRequest.builder()
                .holdBy("MGR01").reason("Customer inspection")
                .build();

        StockUpdateResult result = stockManagementService.holdVehicle("1HGCM82633A004352", request);

        assertTrue(result.success());
        verify(stockPositionService).processHold("1HGCM82633A004352", "D0001", "MGR01", "Customer inspection");
    }

    @Test
    @DisplayName("STKHLD00: holdVehicle non-AV vehicle rejects")
    void holdVehicle_nonAV_throwsException() {
        testVehicle.setVehicleStatus("HD");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        StockHoldRequest request = StockHoldRequest.builder()
                .holdBy("MGR01").reason("Already held")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> stockManagementService.holdVehicle("1HGCM82633A004352", request));
        assertTrue(ex.getMessage().contains("Available (AV)"));
    }

    // ── STKHLD00 RLSE: releaseVehicle ───────────────────────────────────

    @Test
    @DisplayName("STKHLD00 RLSE: releaseVehicle delegates to StockPositionService, requires HD status")
    void releaseVehicle_delegatesAndRequiresHD() {
        testVehicle.setVehicleStatus("HD");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        StockUpdateResult expectedResult = new StockUpdateResult(
                "1HGCM82633A004352", "HD", "AV", "D0001", true, "Vehicle released from hold");
        when(stockPositionService.processRelease(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(expectedResult);

        StockReleaseRequest request = StockReleaseRequest.builder()
                .releaseBy("MGR01").reason("Inspection complete")
                .build();

        StockUpdateResult result = stockManagementService.releaseVehicle("1HGCM82633A004352", request);

        assertTrue(result.success());
        verify(stockPositionService).processRelease("1HGCM82633A004352", "D0001", "MGR01", "Inspection complete");
    }

    // ── STKRCN00: reconcile ─────────────────────────────────────────────

    @Test
    @DisplayName("STKRCN00: reconcile detects variance between system and actual counts")
    void reconcile_detectsVariance() {
        // System count: onHand(8) + onHold(1) + allocated(2) = 11
        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(testPosition));

        // Actual: only 1 vehicle matching the model
        when(vehicleRepository.findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                eq("D0001"), eq(List.of("AV", "HD", "AL"))))
                .thenReturn(List.of(testVehicle)); // 1 vehicle

        when(modelMasterRepository.findById(any(ModelMasterId.class))).thenReturn(Optional.empty());

        ReconciliationResponse result = stockManagementService.reconcile("D0001");

        assertFalse(result.isReconciled());
        assertEquals(1, result.getDiscrepancies().size());
        ReconciliationResponse.Discrepancy d = result.getDiscrepancies().get(0);
        assertEquals(11, d.getSystemCount()); // 8 + 1 + 2
        assertEquals(1, d.getActualCount());
        assertEquals(-10, d.getVariance()); // 1 - 11
    }

    @Test
    @DisplayName("STKRCN00: reconcile no variance returns reconciled=true")
    void reconcile_noVariance_reconciled() {
        // System count matches actual (all zeros)
        StockPosition emptyPosition = StockPosition.builder()
                .dealerCode("D0001").modelYear((short) 2025).makeCode("FORD").modelCode("F150")
                .onHandCount((short) 0).inTransitCount((short) 0).allocatedCount((short) 0)
                .onHoldCount((short) 0).soldMtd((short) 0).soldYtd((short) 0)
                .reorderPoint((short) 5).updatedTs(LocalDateTime.now())
                .build();

        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(emptyPosition));
        when(vehicleRepository.findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                eq("D0001"), any())).thenReturn(Collections.emptyList());

        ReconciliationResponse result = stockManagementService.reconcile("D0001");

        assertTrue(result.isReconciled());
        assertTrue(result.getDiscrepancies().isEmpty());
        assertEquals(0, result.getTotalVariance());
    }

    // ── STKVALS0: getValuation ──────────────────────────────────────────

    @Test
    @DisplayName("STKVALS0: getValuation groups by category with holding cost calculation")
    void getValuation_groupsByCategoryWithHoldingCost() {
        when(vehicleRepository.findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                eq("D0001"), eq(List.of("AV", "DM", "HD", "AL"))))
                .thenReturn(List.of(testVehicle)); // AV vehicle, 20 days in stock

        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.of(PriceMaster.builder()
                        .invoicePrice(new BigDecimal("30000.00"))
                        .msrp(new BigDecimal("35000.00"))
                        .build()));

        StockValuationResponse result = stockManagementService.getValuation("D0001");

        assertEquals("D0001", result.getDealerCode());
        assertFalse(result.getCategories().isEmpty());

        StockValuationResponse.ValuationCategory avCategory = result.getCategories().stream()
                .filter(c -> "AV".equals(c.getCategory()))
                .findFirst().orElseThrow();
        assertEquals("New", avCategory.getCategoryName());
        assertEquals(1, avCategory.getCount());
        assertEquals(new BigDecimal("30000.00"), avCategory.getTotalInvoice());
        assertEquals(new BigDecimal("35000.00"), avCategory.getTotalMsrp());
        // holdingCost = 30000 * 0.000164 * 20 = 98.40
        assertEquals(new BigDecimal("98.40"), avCategory.getHoldingCost());
    }
}
