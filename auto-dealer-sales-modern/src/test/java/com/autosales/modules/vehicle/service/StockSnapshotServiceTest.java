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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

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
 * Unit tests for StockSnapshotService — daily stock position snapshot capture and reporting.
 * Port of STKSNAP0.cbl — end-of-day stock position snapshot batch program.
 */
@ExtendWith(MockitoExtension.class)
class StockSnapshotServiceTest {

    @Mock private StockSnapshotRepository stockSnapshotRepository;
    @Mock private StockPositionRepository stockPositionRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private PriceMasterRepository priceMasterRepository;

    @InjectMocks
    private StockSnapshotService stockSnapshotService;

    // Common test fixtures
    private StockPosition testPosition;

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
    }

    // ── STKSNAP0: captureSnapshot ───────────────────────────────────────

    @Test
    @DisplayName("STKSNAP0: captureSnapshot creates snapshot records, deletes existing first")
    void captureSnapshot_createsRecordsAndDeletesExisting() {
        LocalDate today = LocalDate.now();
        SnapshotCaptureRequest request = SnapshotCaptureRequest.builder()
                .dealerCode("D0001")
                .snapshotDate(today)
                .build();

        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(testPosition));
        when(vehicleRepository.findByDealerCodeAndVehicleStatus("D0001", "AV"))
                .thenReturn(Collections.emptyList());
        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.of(PriceMaster.builder().invoicePrice(new BigDecimal("30000.00")).build()));
        when(stockSnapshotRepository.save(any(StockSnapshot.class))).thenAnswer(inv -> inv.getArgument(0));

        int count = stockSnapshotService.captureSnapshot(request);

        assertEquals(1, count);
        verify(stockSnapshotRepository).deleteByDealerCodeAndSnapshotDate("D0001", today);
        verify(stockSnapshotRepository).save(argThat(snap ->
                snap.getDealerCode().equals("D0001")
                        && snap.getOnHandCount() == 8
                        && snap.getInTransitCount() == 3
                        && snap.getOnHoldCount() == 1
                        && snap.getTotalValue().compareTo(new BigDecimal("240000.00")) == 0
        ));
    }

    @Test
    @DisplayName("STKSNAP0: captureSnapshot defaults date to today when null")
    void captureSnapshot_defaultsDateToToday() {
        SnapshotCaptureRequest request = SnapshotCaptureRequest.builder()
                .dealerCode("D0001")
                .snapshotDate(null) // should default to today
                .build();

        when(stockPositionRepository.findByDealerCode("D0001")).thenReturn(List.of(testPosition));
        when(vehicleRepository.findByDealerCodeAndVehicleStatus("D0001", "AV"))
                .thenReturn(Collections.emptyList());
        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.empty());
        when(stockSnapshotRepository.save(any(StockSnapshot.class))).thenAnswer(inv -> inv.getArgument(0));

        stockSnapshotService.captureSnapshot(request);

        verify(stockSnapshotRepository).deleteByDealerCodeAndSnapshotDate(eq("D0001"), eq(LocalDate.now()));
    }

    @Test
    @DisplayName("STKSNAP0: captureSnapshot all dealers when dealerCode is null")
    void captureSnapshot_allDealers_whenDealerCodeNull() {
        SnapshotCaptureRequest request = SnapshotCaptureRequest.builder()
                .dealerCode(null)
                .snapshotDate(LocalDate.of(2026, 3, 30))
                .build();

        when(stockPositionRepository.findAll()).thenReturn(List.of(testPosition));
        when(vehicleRepository.findByDealerCodeAndVehicleStatus("D0001", "AV"))
                .thenReturn(Collections.emptyList());
        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.empty());
        when(stockSnapshotRepository.save(any(StockSnapshot.class))).thenAnswer(inv -> inv.getArgument(0));

        int count = stockSnapshotService.captureSnapshot(request);

        assertEquals(1, count);
        verify(stockSnapshotRepository).deleteBySnapshotDate(LocalDate.of(2026, 3, 30));
        verify(stockSnapshotRepository, never()).deleteByDealerCodeAndSnapshotDate(any(), any());
    }

    // ── getSnapshots ────────────────────────────────────────────────────

    @Test
    @DisplayName("STKSNAP0: getSnapshots returns paginated results")
    void getSnapshots_returnsPaginatedResults() {
        StockSnapshot snapshot = StockSnapshot.builder()
                .snapshotDate(LocalDate.now())
                .dealerCode("D0001")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .onHandCount((short) 8)
                .inTransitCount((short) 3)
                .onHoldCount((short) 1)
                .totalValue(new BigDecimal("240000.00"))
                .avgDaysInStock((short) 20)
                .build();

        Page<StockSnapshot> page = new PageImpl<>(List.of(snapshot), PageRequest.of(0, 20), 1);
        when(stockSnapshotRepository.findByDealerCodeAndSnapshotDateBetween(
                eq("D0001"), any(LocalDate.class), any(LocalDate.class), any(PageRequest.class)))
                .thenReturn(page);

        PaginatedResponse<SnapshotResponse> result =
                stockSnapshotService.getSnapshots("D0001", null, null, 0, 20);

        assertEquals(1, result.content().size());
        SnapshotResponse resp = result.content().get(0);
        assertEquals("D0001", resp.getDealerCode());
        assertEquals("2025 HONDA ACCORD", resp.getModelDesc());
        assertEquals(new BigDecimal("240000.00"), resp.getTotalValue());
    }
}
