package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.SequenceGenerator;
import com.autosales.common.util.StockPositionService;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.entity.*;
import com.autosales.modules.vehicle.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for ProductionLogisticsService — production order, shipment, transit, delivery, PDI, ETA.
 * Port of PLIPROD0, PLISHPN0, PLITRNS0, PLIDLVR0, PLIVPDS0, PLIALLO0, PLIETA00, PLIRECON.
 */
@ExtendWith(MockitoExtension.class)
class ProductionLogisticsServiceTest {

    @Mock private ProductionOrderRepository productionOrderRepository;
    @Mock private ShipmentRepository shipmentRepository;
    @Mock private ShipmentVehicleRepository shipmentVehicleRepository;
    @Mock private TransitStatusRepository transitStatusRepository;
    @Mock private PdiScheduleRepository pdiScheduleRepository;
    @Mock private VehicleRepository vehicleRepository;
    @Mock private VehicleOptionRepository vehicleOptionRepository;
    @Mock private StockPositionService stockPositionService;
    @Mock private DealerRepository dealerRepository;
    @Mock private SequenceGenerator sequenceGenerator;

    @InjectMocks
    private ProductionLogisticsService productionLogisticsService;

    // Common test fixtures
    private Vehicle testVehicle;
    private ProductionOrder testOrder;
    private Shipment testShipment;
    private PdiSchedule testPdi;

    @BeforeEach
    void setUp() {
        testVehicle = Vehicle.builder()
                .vin("1HGCM82633A004352")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .exteriorColor("White")
                .interiorColor("Black")
                .vehicleStatus("PR")
                .dealerCode("D0001")
                .daysInStock((short) 0)
                .pdiComplete("N")
                .damageFlag("N")
                .odometer(0)
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testOrder = ProductionOrder.builder()
                .productionId("PO123")
                .vin("1HGCM82633A004352")
                .modelYear((short) 2025)
                .makeCode("HONDA")
                .modelCode("ACCORD")
                .plantCode("PLANT01")
                .buildDate(LocalDate.now().minusDays(10))
                .buildStatus("PR")
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testShipment = Shipment.builder()
                .shipmentId("SH001")
                .carrierCode("CARR01")
                .carrierName("Fast Freight")
                .originPlant("PLANT01")
                .destDealer("D0001")
                .transportMode("TK")
                .vehicleCount((short) 0)
                .shipDate(LocalDate.now())
                .estArrivalDate(LocalDate.now().plusDays(3))
                .shipmentStatus("CR")
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        testPdi = PdiSchedule.builder()
                .pdiId(1)
                .vin("1HGCM82633A004352")
                .dealerCode("D0001")
                .scheduledDate(LocalDate.now().plusDays(1))
                .pdiStatus("SC")
                .checklistItems((short) 42)
                .itemsPassed((short) 0)
                .itemsFailed((short) 0)
                .build();
    }

    // ── PLIPROD0: createOrder ───────────────────────────────────────────

    @Test
    @DisplayName("PLIPROD0: createOrder inserts Vehicle(PR) + ProductionOrder")
    void createOrder_createsVehicleAndOrder() {
        ProductionOrderRequest req = ProductionOrderRequest.builder()
                .vin("NEWVIN12345678901")
                .modelYear((short) 2025).makeCode("HONDA").modelCode("CIVIC")
                .plantCode("PLANT01").buildDate(LocalDate.now())
                .build();

        when(vehicleRepository.existsById("NEWVIN12345678901")).thenReturn(false);
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(productionOrderRepository.save(any(ProductionOrder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("NEWVIN12345678901")).thenReturn(Optional.empty());

        ProductionOrderResponse result = productionLogisticsService.createOrder(req);

        assertEquals("NEWVIN12345678901", result.getVin());
        assertEquals("PR", result.getBuildStatus());
        assertEquals("Produced", result.getBuildStatusName());

        // Vehicle created with status PR
        ArgumentCaptor<Vehicle> vehicleCaptor = ArgumentCaptor.forClass(Vehicle.class);
        verify(vehicleRepository).save(vehicleCaptor.capture());
        assertEquals("PR", vehicleCaptor.getValue().getVehicleStatus());
        assertEquals("N", vehicleCaptor.getValue().getPdiComplete());

        // Production order created
        verify(productionOrderRepository).save(any(ProductionOrder.class));
    }

    @Test
    @DisplayName("PLIPROD0: createOrder duplicate VIN rejects")
    void createOrder_duplicateVin_throwsException() {
        ProductionOrderRequest req = ProductionOrderRequest.builder()
                .vin("1HGCM82633A004352").modelYear((short) 2025)
                .makeCode("HONDA").modelCode("ACCORD").plantCode("PLANT01")
                .build();

        when(vehicleRepository.existsById("1HGCM82633A004352")).thenReturn(true);

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> productionLogisticsService.createOrder(req));
        assertTrue(ex.getMessage().contains("already exists"));
    }

    // ── PLIALLO0: allocateOrder ─────────────────────────────────────────

    @Test
    @DisplayName("PLIALLO0: allocateOrder PR->AL, stockPositionService.processAllocate called")
    void allocateOrder_success() {
        when(productionOrderRepository.findById("PO123")).thenReturn(Optional.of(testOrder));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(dealerRepository.existsById("D0001")).thenReturn(true);
        when(productionOrderRepository.save(any(ProductionOrder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        ProductionAllocateRequest req = ProductionAllocateRequest.builder()
                .allocatedDealer("D0001")
                .build();

        ProductionOrderResponse result = productionLogisticsService.allocateOrder("PO123", req);

        assertEquals("AL", result.getBuildStatus());
        verify(vehicleRepository).save(argThat(v -> "AL".equals(v.getVehicleStatus())));
        verify(stockPositionService).processAllocate("1HGCM82633A004352", "D0001",
                "SYSTEM", "Production order allocated: PO123");
    }

    @Test
    @DisplayName("PLIALLO0: allocateOrder wrong vehicle status rejects")
    void allocateOrder_wrongStatus_throwsException() {
        testVehicle.setVehicleStatus("AV"); // not PR
        when(productionOrderRepository.findById("PO123")).thenReturn(Optional.of(testOrder));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        ProductionAllocateRequest req = ProductionAllocateRequest.builder()
                .allocatedDealer("D0001")
                .build();

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> productionLogisticsService.allocateOrder("PO123", req));
        assertTrue(ex.getMessage().contains("cannot be allocated"));
    }

    // ── PLISHPN0: createShipment ────────────────────────────────────────

    @Test
    @DisplayName("PLISHPN0: createShipment ETA calculated by transport mode (TK=+3, RL=+7, OC=+21, AR=+1)")
    void createShipment_etaByTransportMode() {
        // Test truck mode: +3 days
        ShipmentRequest reqTruck = ShipmentRequest.builder()
                .carrierCode("CARR01").carrierName("Trucking Co")
                .originPlant("PLANT01").destDealer("D0001")
                .transportMode("TK").shipDate(LocalDate.of(2026, 4, 1))
                .build();

        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        ShipmentResponse result = productionLogisticsService.createShipment(reqTruck);

        assertEquals("CR", result.getShipmentStatus());
        assertEquals(LocalDate.of(2026, 4, 4), result.getEstArrivalDate()); // +3 days for TK

        // Test rail mode: +7 days
        ShipmentRequest reqRail = ShipmentRequest.builder()
                .carrierCode("CARR02").carrierName("Rail Co")
                .originPlant("PLANT01").destDealer("D0001")
                .transportMode("RL").shipDate(LocalDate.of(2026, 4, 1))
                .build();

        result = productionLogisticsService.createShipment(reqRail);
        assertEquals(LocalDate.of(2026, 4, 8), result.getEstArrivalDate()); // +7 days for RL
    }

    // ── PLISHPN0: addVehicleToShipment ──────────────────────────────────

    @Test
    @DisplayName("PLISHPN0: addVehicleToShipment vehicle must be AL, shipment must be CR")
    void addVehicleToShipment_success() {
        testVehicle.setVehicleStatus("AL");
        when(shipmentRepository.findById("SH001")).thenReturn(Optional.of(testShipment));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(shipmentVehicleRepository.save(any(ShipmentVehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentVehicleRepository.findByShipmentId("SH001")).thenReturn(List.of(
                ShipmentVehicle.builder().shipmentId("SH001").vin("1HGCM82633A004352").loadSequence((short) 1).build()
        ));

        ShipmentVehicleRequest req = ShipmentVehicleRequest.builder()
                .vin("1HGCM82633A004352").loadSequence((short) 1)
                .build();

        ShipmentResponse result = productionLogisticsService.addVehicleToShipment("SH001", req);

        assertEquals((short) 1, result.getVehicleCount());
        verify(shipmentVehicleRepository).save(argThat(sv ->
                "SH001".equals(sv.getShipmentId()) && "1HGCM82633A004352".equals(sv.getVin())));
    }

    // ── PLISHPN0: dispatchShipment ──────────────────────────────────────

    @Test
    @DisplayName("PLISHPN0: dispatchShipment all vehicles -> SH status, shipment -> DP")
    void dispatchShipment_success() {
        testShipment.setVehicleCount((short) 1);
        when(shipmentRepository.findById("SH001")).thenReturn(Optional.of(testShipment));
        ShipmentVehicle sv = ShipmentVehicle.builder()
                .shipmentId("SH001").vin("1HGCM82633A004352").loadSequence((short) 1)
                .build();
        when(shipmentVehicleRepository.findByShipmentId("SH001")).thenReturn(List.of(sv));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        ShipmentResponse result = productionLogisticsService.dispatchShipment("SH001");

        assertEquals("DP", result.getShipmentStatus());
        verify(vehicleRepository).save(argThat(v -> "SH".equals(v.getVehicleStatus())));
    }

    @Test
    @DisplayName("PLISHPN0: dispatchShipment empty shipment rejects")
    void dispatchShipment_empty_throwsException() {
        testShipment.setVehicleCount((short) 0);
        when(shipmentRepository.findById("SH001")).thenReturn(Optional.of(testShipment));

        BusinessValidationException ex = assertThrows(BusinessValidationException.class,
                () -> productionLogisticsService.dispatchShipment("SH001"));
        assertTrue(ex.getMessage().contains("no vehicles"));
    }

    // ── PLITRNS0: addTransitStatus ──────────────────────────────────────

    @Test
    @DisplayName("PLITRNS0: addTransitStatus auto-increments statusSeq")
    void addTransitStatus_autoIncrementsSeq() {
        TransitStatus existing = TransitStatus.builder()
                .vin("1HGCM82633A004352").statusSeq(3).statusCode("IT")
                .locationDesc("Chicago Hub").statusTs(LocalDateTime.now()).receivedTs(LocalDateTime.now())
                .build();
        when(transitStatusRepository.findTopByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(Optional.of(existing));
        when(transitStatusRepository.save(any(TransitStatus.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentVehicleRepository.findByVin("1HGCM82633A004352")).thenReturn(Optional.empty());

        TransitStatusRequest req = TransitStatusRequest.builder()
                .vin("1HGCM82633A004352").locationDesc("Detroit Terminal")
                .statusCode("IT").ediRefNum("EDI-456")
                .build();

        productionLogisticsService.addTransitStatus(req);

        ArgumentCaptor<TransitStatus> captor = ArgumentCaptor.forClass(TransitStatus.class);
        verify(transitStatusRepository).save(captor.capture());
        assertEquals(4, captor.getValue().getStatusSeq()); // 3 + 1
    }

    @Test
    @DisplayName("PLITRNS0: addTransitStatus DL status updates vehicle to DL")
    void addTransitStatus_DL_updatesVehicle() {
        when(transitStatusRepository.findTopByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(Optional.empty());
        when(transitStatusRepository.save(any(TransitStatus.class))).thenAnswer(inv -> inv.getArgument(0));

        // Mock shipment lookup for DL status update
        ShipmentVehicle sv = ShipmentVehicle.builder().shipmentId("SH001").vin("1HGCM82633A004352").build();
        when(shipmentVehicleRepository.findByVin("1HGCM82633A004352")).thenReturn(Optional.of(sv));
        when(shipmentRepository.findById("SH001")).thenReturn(Optional.of(testShipment));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        TransitStatusRequest req = TransitStatusRequest.builder()
                .vin("1HGCM82633A004352").locationDesc("Dealer D0001")
                .statusCode("DL")
                .build();

        productionLogisticsService.addTransitStatus(req);

        verify(vehicleRepository).save(argThat(v -> "DL".equals(v.getVehicleStatus())));
    }

    // ── PLIDLVR0: deliverShipment ───────────────────────────────────────

    @Test
    @DisplayName("PLIDLVR0: deliverShipment all vehicles DL, PDI scheduled, stockPositionService called")
    void deliverShipment_success() {
        when(shipmentRepository.findById("SH001")).thenReturn(Optional.of(testShipment));
        ShipmentVehicle sv = ShipmentVehicle.builder()
                .shipmentId("SH001").vin("1HGCM82633A004352").loadSequence((short) 1)
                .build();
        when(shipmentVehicleRepository.findByShipmentId("SH001")).thenReturn(List.of(sv));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));
        when(shipmentRepository.save(any(Shipment.class))).thenAnswer(inv -> inv.getArgument(0));

        ShipmentDeliverRequest req = ShipmentDeliverRequest.builder()
                .receivedBy("TECH01").notes("All clear")
                .build();

        ShipmentResponse result = productionLogisticsService.deliverShipment("SH001", req);

        assertEquals("DL", result.getShipmentStatus());

        // Vehicle status set to DL
        verify(vehicleRepository).save(argThat(v -> "DL".equals(v.getVehicleStatus())));

        // PDI scheduled with 42 items
        ArgumentCaptor<PdiSchedule> pdiCaptor = ArgumentCaptor.forClass(PdiSchedule.class);
        verify(pdiScheduleRepository).save(pdiCaptor.capture());
        assertEquals((short) 42, pdiCaptor.getValue().getChecklistItems());
        assertEquals("SC", pdiCaptor.getValue().getPdiStatus());

        // Stock position updated
        verify(stockPositionService).processReceive(eq("1HGCM82633A004352"), eq("D0001"),
                eq("TECH01"), contains("Shipment delivered"));
    }

    // ── PLIVPDS0: schedulePdi ───────────────────────────────────────────

    @Test
    @DisplayName("PLIVPDS0: schedulePdi creates with 42 checklist items, status=SC")
    void schedulePdi_creates42ItemSchedule() {
        PdiScheduleRequest req = PdiScheduleRequest.builder()
                .vin("1HGCM82633A004352").dealerCode("D0001")
                .scheduledDate(LocalDate.now().plusDays(1)).technicianId("TECH01")
                .build();

        when(pdiScheduleRepository.save(any(PdiSchedule.class))).thenAnswer(inv -> {
            PdiSchedule pdi = inv.getArgument(0);
            pdi.setPdiId(10);
            return pdi;
        });
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        PdiScheduleResponse result = productionLogisticsService.schedulePdi(req);

        assertEquals("SC", result.getPdiStatus());
        assertEquals((short) 42, result.getChecklistItems());
        assertEquals((short) 0, result.getItemsPassed());
        assertEquals((short) 0, result.getItemsFailed());
    }

    // ── PLIVPDS0: completePdi ───────────────────────────────────────────

    @Test
    @DisplayName("PLIVPDS0: completePdi SC->IP->CM, vehicle pdiComplete=Y, status->AV")
    void completePdi_success() {
        testPdi.setPdiStatus("IP");
        testPdi.setTechnicianId("TECH01");
        when(pdiScheduleRepository.findById(1)).thenReturn(Optional.of(testPdi));
        when(pdiScheduleRepository.save(any(PdiSchedule.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(inv -> inv.getArgument(0));

        PdiCompleteRequest req = PdiCompleteRequest.builder()
                .itemsPassed((short) 40).itemsFailed((short) 2).notes("Minor items failed")
                .build();

        PdiScheduleResponse result = productionLogisticsService.completePdi(1, req);

        assertEquals("CM", result.getPdiStatus());
        assertEquals((short) 40, result.getItemsPassed());
        assertEquals((short) 2, result.getItemsFailed());

        // Vehicle updated: pdiComplete=Y, status=AV
        verify(vehicleRepository).save(argThat(v ->
                "Y".equals(v.getPdiComplete()) && "AV".equals(v.getVehicleStatus())));

        // Stock position updated
        verify(stockPositionService).processReceive(eq("1HGCM82633A004352"), eq("D0001"),
                eq("TECH01"), contains("PDI completed"));
    }

    // ── PLIVPDS0: failPdi ───────────────────────────────────────────────

    @Test
    @DisplayName("PLIVPDS0: failPdi IP->FL, vehicle NOT set to AV")
    void failPdi_doesNotSetVehicleAV() {
        testPdi.setPdiStatus("IP");
        when(pdiScheduleRepository.findById(1)).thenReturn(Optional.of(testPdi));
        when(pdiScheduleRepository.save(any(PdiSchedule.class))).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        PdiCompleteRequest req = PdiCompleteRequest.builder()
                .itemsPassed((short) 20).itemsFailed((short) 22).notes("Major failures")
                .build();

        PdiScheduleResponse result = productionLogisticsService.failPdi(1, req);

        assertEquals("FL", result.getPdiStatus());
        assertEquals((short) 22, result.getItemsFailed());

        // Vehicle is NOT saved with status change when PDI fails (no AV transition)
        verify(vehicleRepository, never()).save(any(Vehicle.class));
        verify(stockPositionService, never()).processReceive(any(), any(), any(), any());
    }

    // ── PLIETA00: calculateEta ──────────────────────────────────────────

    @Test
    @DisplayName("PLIETA00: calculateEta computes daysInTransit and daysRemaining correctly")
    void calculateEta_computesCorrectly() {
        LocalDate shipDate = LocalDate.now().minusDays(5);
        LocalDate estArrival = LocalDate.now().plusDays(2);

        testVehicle.setVehicleStatus("SH");
        testVehicle.setShipDate(shipDate);
        when(vehicleRepository.findById("1HGCM82633A004352")).thenReturn(Optional.of(testVehicle));

        ShipmentVehicle sv = ShipmentVehicle.builder()
                .shipmentId("SH001").vin("1HGCM82633A004352").loadSequence((short) 1)
                .build();
        when(shipmentVehicleRepository.findByVin("1HGCM82633A004352")).thenReturn(Optional.of(sv));

        Shipment shipment = Shipment.builder()
                .shipmentId("SH001").carrierCode("CARR01").originPlant("PLANT01")
                .destDealer("D0001").transportMode("RL")
                .shipDate(shipDate).estArrivalDate(estArrival)
                .shipmentStatus("DP").vehicleCount((short) 1)
                .createdTs(LocalDateTime.now()).updatedTs(LocalDateTime.now())
                .build();
        when(shipmentRepository.findById("SH001")).thenReturn(Optional.of(shipment));
        when(transitStatusRepository.findTopByVinOrderByStatusSeqDesc("1HGCM82633A004352"))
                .thenReturn(Optional.of(TransitStatus.builder()
                        .vin("1HGCM82633A004352").statusSeq(1).locationDesc("Chicago Hub")
                        .statusCode("IT").statusTs(LocalDateTime.now()).receivedTs(LocalDateTime.now())
                        .build()));

        EtaResponse result = productionLogisticsService.calculateEta("1HGCM82633A004352");

        assertEquals("1HGCM82633A004352", result.getVin());
        assertEquals("2025 HONDA ACCORD", result.getVehicleDesc());
        assertEquals("SH001", result.getShipmentId());
        assertEquals("Chicago Hub", result.getCurrentLocation());
        assertEquals(5, result.getDaysInTransit());
        assertEquals(2, result.getEstimatedDaysRemaining());
        assertEquals(estArrival, result.getEstArrivalDate());
        assertEquals("RL", result.getTransportMode());
    }
}
