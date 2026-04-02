package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.FieldFormatter;
import com.autosales.common.util.SequenceGenerator;
import com.autosales.common.util.StockPositionService;
import com.autosales.common.util.StockUpdateResult;
import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.repository.PriceMasterRepository;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.entity.PdiSchedule;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.entity.VehicleOption;
import com.autosales.modules.vehicle.entity.VehicleStatusHist;
import com.autosales.modules.vehicle.repository.LotLocationRepository;
import com.autosales.modules.vehicle.repository.PdiScheduleRepository;
import com.autosales.modules.vehicle.repository.VehicleOptionRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import com.autosales.modules.vehicle.repository.VehicleStatusHistRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
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
 * Unit tests for VehicleService — core vehicle inventory lifecycle.
 * Port of VEHINQ00, VEHLST00, VEHUPD00, VEHRCV00, VEHALL00, VEHAGE00.
 */
@ExtendWith(MockitoExtension.class)
class VehicleServiceTest {

    @Mock private VehicleRepository vehicleRepository;
    @Mock private VehicleOptionRepository vehicleOptionRepository;
    @Mock private VehicleStatusHistRepository vehicleStatusHistRepository;
    @Mock private LotLocationRepository lotLocationRepository;
    @Mock private StockPositionService stockPositionService;
    @Mock private PriceMasterRepository priceMasterRepository;
    @Mock private PdiScheduleRepository pdiScheduleRepository;
    @Mock private FieldFormatter fieldFormatter;
    @Mock private SequenceGenerator sequenceGenerator;

    @InjectMocks
    private VehicleService vehicleService;

    // Common test fixtures
    private Vehicle testVehicle;
    private VehicleOption testOption;
    private VehicleStatusHist testHistory;

    @BeforeEach
    void setUp() {
        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .exteriorColor("White")
                .interiorColor("Black")
                .engineNum("ENG123456")
                .productionDate(LocalDate.of(2025, 1, 15))
                .vehicleStatus("AV")
                .dealerCode("D0001")
                .lotLocation("LOT-A")
                .stockNumber("STK001")
                .daysInStock((short) 15)
                .pdiComplete("Y")
                .damageFlag("N")
                .odometer(25)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testOption = VehicleOption.builder()
                .vin("1HGCM82633A004352")
                .optionCode("NAV")
                .optionDesc("Navigation System")
                .optionPrice(new BigDecimal("1500.00"))
                .installedFlag("Y")
                .build();

        testHistory = VehicleStatusHist.builder()
                .vin("1HGCM82633A004352")
                .statusSeq(1)
                .oldStatus("PR")
                .newStatus("AV")
                .changedBy("SYSTEM")
                .changeReason("Vehicle received")
                .changedTs(LocalDateTime.now())
                .build();
    }

    // ── VEHINQ00: getVehicle ────────────────────────────────────────────

    @Test
    @DisplayName("VEHINQ00: getVehicle success — returns vehicle with options and history")
    void getVehicle_success_returnsFullResponse() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleOptionRepository.findByVin("1HGCM82633A004352")).thenReturn(List.of(testOption));
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(List.of(testHistory));

        VehicleResponse result = vehicleService.getVehicle("1HGCM82633A004352");

        assertEquals("1HGCM82633A004352", result.getVin());
        assertEquals("2025 HONDA ACCORD", result.getVehicleDesc());
        assertEquals("Available", result.getStatusName());
        assertEquals(1, result.getOptions().size());
        assertEquals("NAV", result.getOptions().get(0).getOptionCode());
        assertEquals(1, result.getHistory().size());
    }

    @Test
    @DisplayName("VEHINQ00: getVehicle not found throws EntityNotFoundException")
    void getVehicle_notFound_throwsException() {
        when(vehicleRepository.findById("BADVIN")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class, () -> vehicleService.getVehicle("BADVIN"));
    }

    // ── VEHLST00: listVehicles ──────────────────────────────────────────

    @Test
    @DisplayName("VEHLST00: listVehicles returns paginated results with vehicleDesc")
    void listVehicles_returnsPaginatedResults() {
        Page<Vehicle> page = new PageImpl<>(List.of(testVehicle), PageRequest.of(0, 20), 1);
        when(vehicleRepository.searchVehicles(eq("D0001"), isNull(), isNull(), isNull(), isNull(), isNull(), any()))
                .thenReturn(page);

        var result = vehicleService.listVehicles("D0001", null, null, null, null, null, 0, 20);

        assertEquals(1, result.content().size());
        assertEquals("2025 HONDA ACCORD", result.content().get(0).getVehicleDesc());
        assertEquals(1, result.totalElements());
    }

    // ── VEHUPD00: updateVehicle ─────────────────────────────────────────

    @Test
    @DisplayName("VEHUPD00: updateVehicle valid transition AV->HD with status history recorded")
    void updateVehicle_validTransition_AV_to_HD() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(Optional.of(testHistory));
        when(vehicleOptionRepository.findByVin("1HGCM82633A004352")).thenReturn(Collections.emptyList());
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(Collections.emptyList());

        VehicleUpdateRequest request = VehicleUpdateRequest.builder()
                .vehicleStatus("HD")
                .reason("Customer requested hold")
                .build();

        VehicleResponse result = vehicleService.updateVehicle("1HGCM82633A004352", request);

        assertEquals("HD", result.getVehicleStatus());
        verify(vehicleStatusHistRepository).save(argThat(h ->
                "AV".equals(h.getOldStatus()) && "HD".equals(h.getNewStatus())));
    }

    @Test
    @DisplayName("VEHUPD00: updateVehicle invalid transition SD->AV rejects — use deal unwind")
    void updateVehicle_SD_to_AV_rejects() {
        testVehicle.setVehicleStatus("SD");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        VehicleUpdateRequest request = VehicleUpdateRequest.builder()
                .vehicleStatus("AV")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> vehicleService.updateVehicle("1HGCM82633A004352", request));
        assertTrue(ex.getMessage().contains("deal unwind"));
    }

    @Test
    @DisplayName("VEHUPD00: updateVehicle WO/RJ always allowed from any status")
    void updateVehicle_WO_alwaysAllowed() {
        testVehicle.setVehicleStatus("IT");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Optional.of(testHistory));
        when(vehicleOptionRepository.findByVin(anyString())).thenReturn(Collections.emptyList());
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Collections.emptyList());

        VehicleUpdateRequest request = VehicleUpdateRequest.builder()
                .vehicleStatus("WO")
                .reason("Total loss")
                .build();

        VehicleResponse result = vehicleService.updateVehicle("1HGCM82633A004352", request);

        assertEquals("WO", result.getVehicleStatus());
    }

    @Test
    @DisplayName("VEHUPD00: updateVehicle no status change — only field updates")
    void updateVehicle_noStatusChange_fieldsOnly() {
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleOptionRepository.findByVin(anyString())).thenReturn(Collections.emptyList());
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Collections.emptyList());

        VehicleUpdateRequest request = VehicleUpdateRequest.builder()
                .odometer(500)
                .keyNumber("KEY-999")
                .build();

        VehicleResponse result = vehicleService.updateVehicle("1HGCM82633A004352", request);

        assertEquals(500, result.getOdometer());
        assertEquals("KEY-999", result.getKeyNumber());
        // No status history recorded for field-only update
        verify(vehicleStatusHistRepository, never()).save(any(VehicleStatusHist.class));
    }

    // ── VEHRCV00: receiveVehicle ────────────────────────────────────────

    @Test
    @DisplayName("VEHRCV00: receiveVehicle PR->AV, stock number generated, PDI scheduled (42 items)")
    void receiveVehicle_success_generatesStockAndPdi() {
        testVehicle.setVehicleStatus("PR");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(sequenceGenerator.generateStockNumber()).thenReturn("STK-AUTO-001");
        when(vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Optional.empty());
        when(vehicleOptionRepository.findByVin(anyString())).thenReturn(Collections.emptyList());
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Collections.emptyList());

        VehicleReceiveRequest request = VehicleReceiveRequest.builder()
                .lotLocation("LOT-A")
                .odometer(5)
                .damageFlag("N")
                .build();

        VehicleResponse result = vehicleService.receiveVehicle("1HGCM82633A004352", request);

        assertEquals("AV", result.getVehicleStatus());
        assertEquals("STK-AUTO-001", result.getStockNumber());

        // PDI schedule created with 42 checklist items
        ArgumentCaptor<PdiSchedule> pdiCaptor = ArgumentCaptor.forClass(PdiSchedule.class);
        verify(pdiScheduleRepository).save(pdiCaptor.capture());
        assertEquals((short) 42, pdiCaptor.getValue().getChecklistItems());
        assertEquals("SC", pdiCaptor.getValue().getPdiStatus());

        // Stock position updated
        verify(stockPositionService).processReceive(eq("1HGCM82633A004352"), eq("D0001"),
                eq("SYSTEM"), anyString());
    }

    @Test
    @DisplayName("VEHRCV00: receiveVehicle wrong status (AV) rejects")
    void receiveVehicle_wrongStatus_rejects() {
        testVehicle.setVehicleStatus("AV");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        VehicleReceiveRequest request = VehicleReceiveRequest.builder().build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> vehicleService.receiveVehicle("1HGCM82633A004352", request));
        assertTrue(ex.getMessage().contains("PR, AL, or IT"));
    }

    @Test
    @DisplayName("VEHRCV00: receiveVehicle calls stockPositionService.processReceive")
    void receiveVehicle_callsStockPositionService() {
        testVehicle.setVehicleStatus("IT");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(sequenceGenerator.generateStockNumber()).thenReturn("STK-002");
        when(vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Optional.empty());
        when(vehicleOptionRepository.findByVin(anyString())).thenReturn(Collections.emptyList());
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Collections.emptyList());

        vehicleService.receiveVehicle("1HGCM82633A004352", VehicleReceiveRequest.builder().build());

        verify(stockPositionService).processReceive(
                eq("1HGCM82633A004352"), eq("D0001"), eq("SYSTEM"), anyString());
    }

    // ── VEHALL00: allocateVehicle ───────────────────────────────────────

    @Test
    @DisplayName("VEHALL00: allocateVehicle PR->AL with stockPositionService.processAllocate called")
    void allocateVehicle_success() {
        testVehicle.setVehicleStatus("PR");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleStatusHistRepository.findTopByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Optional.empty());
        when(vehicleOptionRepository.findByVin(anyString())).thenReturn(Collections.emptyList());
        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc(anyString()))
                .thenReturn(Collections.emptyList());

        VehicleAllocateRequest request = VehicleAllocateRequest.builder()
                .reason("Factory allocation")
                .build();

        VehicleResponse result = vehicleService.allocateVehicle("1HGCM82633A004352", request);

        assertEquals("AL", result.getVehicleStatus());
        verify(stockPositionService).processAllocate(
                eq("1HGCM82633A004352"), eq("D0001"), eq("SYSTEM"), eq("Factory allocation"));
    }

    @Test
    @DisplayName("VEHALL00: allocateVehicle wrong status (AV) rejects")
    void allocateVehicle_wrongStatus_rejects() {
        testVehicle.setVehicleStatus("AV");
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        VehicleAllocateRequest request = VehicleAllocateRequest.builder().reason("Test").build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> vehicleService.allocateVehicle("1HGCM82633A004352", request));
        assertTrue(ex.getMessage().contains("PR status"));
    }

    // ── VEHAGE00: getAgingReport ────────────────────────────────────────

    @Test
    @DisplayName("VEHAGE00: getAgingReport 5 buckets calculated correctly")
    void getAgingReport_calculatesAgingBuckets() {
        // Vehicle received 45 days ago (bucket 31-60)
        Vehicle v1 = Vehicle.builder()
                .vin("VIN001").modelYear((short) 2025).makeCode("HONDA").modelCode("CIVIC")
                .exteriorColor("Red").interiorColor("Black").vehicleStatus("AV")
                .dealerCode("D0001").daysInStock((short) 45).pdiComplete("Y").damageFlag("N")
                .receiveDate(LocalDate.now().minusDays(45))
                .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now())
                .build();

        // Vehicle received 95 days ago (bucket 91-120, aged)
        Vehicle v2 = Vehicle.builder()
                .vin("VIN002").modelYear((short) 2025).makeCode("HONDA").modelCode("ACCORD")
                .exteriorColor("Blue").interiorColor("Gray").vehicleStatus("AV")
                .dealerCode("D0001").daysInStock((short) 95).pdiComplete("Y").damageFlag("N")
                .receiveDate(LocalDate.now().minusDays(95))
                .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now())
                .build();

        when(vehicleRepository.findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                eq("D0001"), eq(List.of("AV", "HD", "AL"))))
                .thenReturn(List.of(v1, v2));

        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.of(PriceMaster.builder().invoicePrice(new BigDecimal("25000.00")).build()));

        AgingReportResponse result = vehicleService.getAgingReport("D0001");

        assertEquals("D0001", result.getDealerCode());
        assertEquals(2, result.getTotalVehicles());
        assertEquals(5, result.getBuckets().size());
        assertEquals("0-30", result.getBuckets().get(0).getRange());
        assertEquals("31-60", result.getBuckets().get(1).getRange());
        assertEquals("120+", result.getBuckets().get(4).getRange());
        // v1 in bucket 1 (31-60), v2 in bucket 3 (91-120)
        assertEquals(1, result.getBuckets().get(1).getCount());
        assertEquals(1, result.getBuckets().get(3).getCount());
    }

    @Test
    @DisplayName("VEHAGE00: getAgingReport flags 90+ day vehicles as aged")
    void getAgingReport_flags90PlusAsAged() {
        Vehicle agedVehicle = Vehicle.builder()
                .vin("VIN-AGED").modelYear((short) 2025).makeCode("TOYOTA").modelCode("CAMRY")
                .exteriorColor("Silver").interiorColor("Black").vehicleStatus("AV")
                .dealerCode("D0001").lotLocation("LOT-A").stockNumber("STK-OLD")
                .daysInStock((short) 100).pdiComplete("Y").damageFlag("N")
                .receiveDate(LocalDate.now().minusDays(100))
                .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now())
                .build();

        when(vehicleRepository.findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
                eq("D0001"), any())).thenReturn(List.of(agedVehicle));
        when(priceMasterRepository.findCurrentEffective(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        AgingReportResponse result = vehicleService.getAgingReport("D0001");

        assertFalse(result.getAgedVehicles().isEmpty());
        assertEquals("VIN-AGED", result.getAgedVehicles().get(0).getVin());
    }

    // ── Status History ──────────────────────────────────────────────────

    @Test
    @DisplayName("VehicleService: getStatusHistory returns entries in descending order")
    void getStatusHistory_returnsDescendingOrder() {
        VehicleStatusHist h1 = VehicleStatusHist.builder()
                .vin("1HGCM82633A004352").statusSeq(2).oldStatus("AV").newStatus("HD")
                .changedBy("USER1").changedTs(LocalDateTime.now())
                .build();
        VehicleStatusHist h2 = VehicleStatusHist.builder()
                .vin("1HGCM82633A004352").statusSeq(1).oldStatus("PR").newStatus("AV")
                .changedBy("SYSTEM").changedTs(LocalDateTime.now().minusDays(1))
                .build();

        when(vehicleStatusHistRepository.findByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(List.of(h1, h2));

        List<VehicleHistoryEntry> result = vehicleService.getStatusHistory("1HGCM82633A004352");

        assertEquals(2, result.size());
        assertEquals(2, result.get(0).getStatusSeq()); // newest first
        assertEquals(1, result.get(1).getStatusSeq());
    }
}
