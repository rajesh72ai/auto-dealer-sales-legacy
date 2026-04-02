package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchRunResult;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for WeeklyBatchService — port of BATWKL00.cbl Phase 1.
 * Validates inventory aging: DAYS_IN_STOCK = DAYS(CURRENT DATE) - DAYS(RECEIVE_DATE).
 */
@ExtendWith(MockitoExtension.class)
class WeeklyBatchServiceTest {

    @Mock private BatchControlRepository batchControlRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private com.autosales.modules.registration.repository.WarrantyRepository warrantyRepository;
    @Mock private com.autosales.modules.registration.repository.RecallCampaignRepository recallCampaignRepository;
    @Mock private com.autosales.modules.registration.repository.RecallVehicleRepository recallVehicleRepository;

    @InjectMocks
    private WeeklyBatchService weeklyBatchService;

    // ── Phase 1: Inventory Aging ──────────────────────────────────────

    @Test
    @DisplayName("BATWKL00 Phase 1: DAYS_IN_STOCK = DAYS(TODAY) - DAYS(RECEIVE_DATE)")
    void ageInventory_calculatesCorrectDays() {
        LocalDate receiveDate = LocalDate.now().minusDays(45);
        Vehicle vehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .vehicleStatus("AV")
                .receiveDate(receiveDate)
                .daysInStock((short) 40) // Old value
                .updatedTs(LocalDateTime.now())
                .build();
        when(vehicleRepository.findAll()).thenReturn(List.of(vehicle));
        when(vehicleRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        int count = weeklyBatchService.ageInventory();

        assertEquals(1, count);
        ArgumentCaptor<Vehicle> captor = ArgumentCaptor.forClass(Vehicle.class);
        verify(vehicleRepository).save(captor.capture());

        short expectedDays = (short) ChronoUnit.DAYS.between(receiveDate, LocalDate.now());
        assertEquals(expectedDays, captor.getValue().getDaysInStock(),
                "BATWKL00: DAYS_IN_STOCK = DAYS(CURRENT DATE) - DAYS(RECEIVE_DATE)");
    }

    @Test
    @DisplayName("BATWKL00 Phase 1: Only AV/HD/DL statuses are aged")
    void ageInventory_onlyStockStatuses() {
        Vehicle soldVehicle = Vehicle.builder()
                .vin("SOLD000000000001")
                .vehicleStatus("SD") // Sold — should NOT be aged
                .receiveDate(LocalDate.now().minusDays(60))
                .build();
        Vehicle avVehicle = Vehicle.builder()
                .vin("AVAIL00000000001")
                .vehicleStatus("AV")
                .receiveDate(LocalDate.now().minusDays(30))
                .daysInStock((short) 0)
                .updatedTs(LocalDateTime.now())
                .build();
        when(vehicleRepository.findAll()).thenReturn(List.of(soldVehicle, avVehicle));
        when(vehicleRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        int count = weeklyBatchService.ageInventory();

        assertEquals(1, count, "BATWKL00: Only AV/HD/DL vehicles are aged per COBOL logic");
        verify(vehicleRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("BATWKL00 Phase 1: Vehicle without receive date is skipped")
    void ageInventory_noReceiveDate_skipped() {
        Vehicle noDateVehicle = Vehicle.builder()
                .vin("NODATE0000000001")
                .vehicleStatus("AV")
                .receiveDate(null)
                .build();
        when(vehicleRepository.findAll()).thenReturn(List.of(noDateVehicle));

        int count = weeklyBatchService.ageInventory();

        assertEquals(0, count);
        verify(vehicleRepository, never()).save(any());
    }

    // ── Full Run ──────────────────────────────────────────────────────

    @Test
    @DisplayName("BATWKL00: Full weekly run — all 3 phases execute with Wave 6 repos wired")
    void runWeeklyProcessing_includesWave6Warnings() {
        when(vehicleRepository.findAll()).thenReturn(List.of());
        when(batchControlRepository.findById("BATWKL00")).thenReturn(Optional.empty());
        when(batchControlRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        // Wave 6 repos return empty results
        lenient().when(warrantyRepository.findAll()).thenReturn(List.of());
        lenient().when(recallCampaignRepository.findByCampaignStatus(any(), any()))
                .thenReturn(org.springframework.data.domain.Page.empty());

        BatchRunResult result = weeklyBatchService.runWeeklyProcessing();

        assertEquals("BATWKL00", result.getProgramId());
        assertEquals("OK", result.getStatus());
        assertEquals(3, result.getPhases().size());
    }
}
