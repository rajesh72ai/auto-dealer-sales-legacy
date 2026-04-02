package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.modules.vehicle.dto.LotLocationRequest;
import com.autosales.modules.vehicle.dto.LotLocationResponse;
import com.autosales.modules.vehicle.entity.LotLocation;
import com.autosales.modules.vehicle.entity.LotLocationId;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.LotLocationRepository;
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
 * Unit tests for LotLocationService — lot location management with capacity tracking.
 * Port of VEHLOC00.cbl — vehicle lot location maintenance transaction.
 */
@ExtendWith(MockitoExtension.class)
class LotLocationServiceTest {

    @Mock private LotLocationRepository lotLocationRepository;
    @Mock private VehicleRepository vehicleRepository;

    @InjectMocks
    private LotLocationService lotLocationService;

    // Common test fixtures
    private LotLocation testLocation;
    private Vehicle testVehicle;

    @BeforeEach
    void setUp() {
        testLocation = LotLocation.builder()
                .dealerCode("D0001")
                .locationCode("LOT-A")
                .locationDesc("Main Front Lot")
                .locationType("L")
                .maxCapacity((short) 50)
                .currentCount((short) 30)
                .activeFlag("Y")
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
                .lotLocation("LOT-B")
                .daysInStock((short) 10)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(15)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ── VEHLOC00: listLocations ─────────────────────────────────────────

    @Test
    @DisplayName("VEHLOC00: listLocations returns locations with calculated availableSpots and utilizationPct")
    void listLocations_returnsLocationsWithMetrics() {
        when(lotLocationRepository.findByDealerCode("D0001")).thenReturn(List.of(testLocation));

        List<LotLocationResponse> result = lotLocationService.listLocations("D0001");

        assertEquals(1, result.size());
        LotLocationResponse resp = result.get(0);
        assertEquals("D0001", resp.getDealerCode());
        assertEquals("LOT-A", resp.getLocationCode());
        assertEquals(20, resp.getAvailableSpots()); // 50 - 30
        assertEquals(new BigDecimal("60.00"), resp.getUtilizationPct()); // 30/50 * 100
    }

    // ── VEHLOC00: createLocation ────────────────────────────────────────

    @Test
    @DisplayName("VEHLOC00: createLocation with valid type (L/S/V/O) and capacity > 0 succeeds")
    void createLocation_validTypeAndCapacity_succeeds() {
        LotLocationRequest request = LotLocationRequest.builder()
                .dealerCode("D0001")
                .locationCode("LOT-C")
                .locationDesc("Service Area")
                .locationType("S")
                .maxCapacity((short) 20)
                .build();

        LotLocationId id = new LotLocationId("D0001", "LOT-C");
        when(lotLocationRepository.existsById(id)).thenReturn(false);

        LotLocation saved = LotLocation.builder()
                .dealerCode("D0001").locationCode("LOT-C")
                .locationDesc("Service Area").locationType("S")
                .maxCapacity((short) 20).currentCount((short) 0).activeFlag("Y")
                .build();
        when(lotLocationRepository.save(any(LotLocation.class))).thenReturn(saved);

        LotLocationResponse result = lotLocationService.createLocation(request);

        assertEquals("LOT-C", result.getLocationCode());
        assertEquals("S", result.getLocationType());
        assertEquals((short) 20, result.getMaxCapacity());
        assertEquals(20, result.getAvailableSpots());

        ArgumentCaptor<LotLocation> captor = ArgumentCaptor.forClass(LotLocation.class);
        verify(lotLocationRepository).save(captor.capture());
        assertEquals("Y", captor.getValue().getActiveFlag());
        assertEquals((short) 0, captor.getValue().getCurrentCount());
    }

    @Test
    @DisplayName("VEHLOC00: createLocation with invalid type rejects with BusinessValidationException")
    void createLocation_invalidType_throwsException() {
        LotLocationRequest request = LotLocationRequest.builder()
                .dealerCode("D0001").locationCode("LOT-X")
                .locationDesc("Bad Type").locationType("Z")
                .maxCapacity((short) 10)
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> lotLocationService.createLocation(request));
        assertTrue(ex.getMessage().contains("Invalid location type"));
        verify(lotLocationRepository, never()).save(any());
    }

    @Test
    @DisplayName("VEHLOC00: createLocation with capacity <= 0 rejects")
    void createLocation_zeroCapacity_throwsException() {
        LotLocationRequest request = LotLocationRequest.builder()
                .dealerCode("D0001").locationCode("LOT-X")
                .locationDesc("Zero Cap").locationType("L")
                .maxCapacity((short) 0)
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> lotLocationService.createLocation(request));
        assertTrue(ex.getMessage().contains("capacity must be greater than 0"));
        verify(lotLocationRepository, never()).save(any());
    }

    // ── VEHLOC00: updateLocation ────────────────────────────────────────

    @Test
    @DisplayName("VEHLOC00: updateLocation partial update works — only provided fields updated")
    void updateLocation_partialUpdate_succeeds() {
        LotLocationId id = new LotLocationId("D0001", "LOT-A");
        when(lotLocationRepository.findById(id)).thenReturn(Optional.of(testLocation));
        when(lotLocationRepository.save(any(LotLocation.class))).thenAnswer(inv -> inv.getArgument(0));

        LotLocationRequest request = LotLocationRequest.builder()
                .locationDesc("Updated Main Lot")
                .build();

        LotLocationResponse result = lotLocationService.updateLocation("D0001", "LOT-A", request);

        assertEquals("Updated Main Lot", result.getLocationDesc());
        assertEquals("L", result.getLocationType()); // unchanged
    }

    // ── VEHLOC00: deactivateLocation ────────────────────────────────────

    @Test
    @DisplayName("VEHLOC00: deactivateLocation sets activeFlag to N")
    void deactivateLocation_setsActiveFlagN() {
        LotLocationId id = new LotLocationId("D0001", "LOT-A");
        when(lotLocationRepository.findById(id)).thenReturn(Optional.of(testLocation));
        when(lotLocationRepository.save(any(LotLocation.class))).thenAnswer(inv -> inv.getArgument(0));

        LotLocationResponse result = lotLocationService.deactivateLocation("D0001", "LOT-A");

        assertEquals("N", result.getActiveFlag());
        verify(lotLocationRepository).save(argThat(loc -> "N".equals(loc.getActiveFlag())));
    }

    // ── VEHLOC00: assignVehicleToLocation ───────────────────────────────

    @Test
    @DisplayName("VEHLOC00: assignVehicleToLocation validates capacity, updates vehicle and counts")
    void assignVehicleToLocation_success() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        LotLocationId newId = new LotLocationId("D0001", "LOT-A");
        when(lotLocationRepository.findById(newId)).thenReturn(Optional.of(testLocation));

        // Old location for decrement
        LotLocation oldLocation = LotLocation.builder()
                .dealerCode("D0001").locationCode("LOT-B")
                .locationDesc("Back Lot").locationType("L")
                .maxCapacity((short) 30).currentCount((short) 10).activeFlag("Y")
                .build();
        LotLocationId oldId = new LotLocationId("D0001", "LOT-B");
        when(lotLocationRepository.findById(oldId)).thenReturn(Optional.of(oldLocation));
        when(lotLocationRepository.save(any(LotLocation.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        lotLocationService.assignVehicleToLocation("1HGCM82633A004352", "D0001", "LOT-A");

        // Verify old location decremented
        verify(lotLocationRepository, times(2)).save(argThat(loc -> {
            if ("LOT-B".equals(loc.getLocationCode())) {
                return loc.getCurrentCount() == 9; // 10 - 1
            }
            if ("LOT-A".equals(loc.getLocationCode())) {
                return loc.getCurrentCount() == 31; // 30 + 1
            }
            return false;
        }));

        // Verify vehicle updated
        verify(vehicleRepository).save(argThat(v -> "LOT-A".equals(v.getLotLocation())));
    }

    @Test
    @DisplayName("VEHLOC00: assignVehicleToLocation at capacity rejects with BusinessValidationException")
    void assignVehicleToLocation_atCapacity_throwsException() {
        testVehicle.setLotLocation(null); // no old location
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        LotLocation fullLocation = LotLocation.builder()
                .dealerCode("D0001").locationCode("LOT-A")
                .locationDesc("Full Lot").locationType("L")
                .maxCapacity((short) 50).currentCount((short) 50).activeFlag("Y")
                .build();
        LotLocationId id = new LotLocationId("D0001", "LOT-A");
        when(lotLocationRepository.findById(id)).thenReturn(Optional.of(fullLocation));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> lotLocationService.assignVehicleToLocation("1HGCM82633A004352", "D0001", "LOT-A"));
        assertTrue(ex.getMessage().contains("full capacity"));
    }
}
