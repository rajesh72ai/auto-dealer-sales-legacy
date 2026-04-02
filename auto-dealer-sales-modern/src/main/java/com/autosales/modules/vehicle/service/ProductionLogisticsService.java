package com.autosales.modules.vehicle.service;

import com.autosales.common.exception.BusinessValidationException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.SequenceGenerator;
import com.autosales.common.util.StockPositionService;
import com.autosales.modules.admin.repository.DealerRepository;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.entity.*;
import com.autosales.modules.vehicle.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Service for end-to-end production logistics management.
 * Port of 8 PLI programs: PLIPROD0, PLISHPN0, PLITRNS0, PLIDLVR0,
 * PLIVPDS0, PLIALLO0, PLIETA00, PLIRECON.
 *
 * <p>Manages the full vehicle lifecycle from factory production order through
 * allocation, shipment, transit tracking, delivery, PDI, and reconciliation.</p>
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class ProductionLogisticsService {

    private static final Map<String, String> BUILD_STATUS_NAMES = Map.of(
            "PR", "Produced",
            "AL", "Allocated",
            "SH", "Shipped",
            "CM", "Complete"
    );

    private static final Map<String, String> SHIPMENT_STATUS_NAMES = Map.of(
            "CR", "Created",
            "DP", "Dispatched",
            "IT", "In Transit",
            "DL", "Delivered"
    );

    private static final Map<String, String> PDI_STATUS_NAMES = Map.of(
            "SC", "Scheduled",
            "IP", "In Progress",
            "CM", "Completed",
            "FL", "Failed"
    );

    /** Transport mode → estimated transit days */
    private static final Map<String, Integer> TRANSIT_DAYS = Map.of(
            "TK", 3, "RL", 7, "OC", 21, "AR", 1
    );
    private static final int DEFAULT_TRANSIT_DAYS = 5;

    private final ProductionOrderRepository productionOrderRepository;
    private final ShipmentRepository shipmentRepository;
    private final ShipmentVehicleRepository shipmentVehicleRepository;
    private final TransitStatusRepository transitStatusRepository;
    private final PdiScheduleRepository pdiScheduleRepository;
    private final VehicleRepository vehicleRepository;
    private final VehicleOptionRepository vehicleOptionRepository;
    private final StockPositionService stockPositionService;
    private final DealerRepository dealerRepository;
    private final SequenceGenerator sequenceGenerator;

    // ═══════════════════════════════════════════════════════════════════��
    // Production Orders (PLIPROD0)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Create a production order and the corresponding vehicle record.
     */
    @Transactional
    public ProductionOrderResponse createOrder(ProductionOrderRequest req) {
        log.info("PRODUCTION ORDER CREATE: vin={}, plant={}, model={}/{}/{}",
                req.getVin(), req.getPlantCode(), req.getModelYear(), req.getMakeCode(), req.getModelCode());

        // Validate VIN not duplicate
        if (vehicleRepository.existsById(req.getVin())) {
            throw new BusinessValidationException("Vehicle with VIN " + req.getVin() + " already exists");
        }

        // Generate production ID
        String productionId = "PO" + System.currentTimeMillis();

        LocalDateTime now = LocalDateTime.now();

        // Create vehicle record with status PR (Produced)
        Vehicle vehicle = Vehicle.builder()
                .vin(req.getVin())
                .modelYear(req.getModelYear())
                .makeCode(req.getMakeCode())
                .modelCode(req.getModelCode())
                .exteriorColor("TBD")
                .interiorColor("TBD")
                .productionDate(req.getBuildDate() != null ? req.getBuildDate() : LocalDate.now())
                .vehicleStatus("PR")
                .daysInStock((short) 0)
                .pdiComplete("N")
                .damageFlag("N")
                .odometer(0)
                .createdTs(now)
                .updatedTs(now)
                .build();
        vehicleRepository.save(vehicle);

        // Create production order
        ProductionOrder order = ProductionOrder.builder()
                .productionId(productionId)
                .vin(req.getVin())
                .modelYear(req.getModelYear())
                .makeCode(req.getMakeCode())
                .modelCode(req.getModelCode())
                .plantCode(req.getPlantCode())
                .buildDate(req.getBuildDate())
                .buildStatus("PR")
                .createdTs(now)
                .updatedTs(now)
                .build();
        ProductionOrder saved = productionOrderRepository.save(order);

        log.info("Production order created: id={}, vin={}", saved.getProductionId(), saved.getVin());
        return toProductionOrderResponse(saved);
    }

    /**
     * Search production orders with optional filters.
     */
    public PaginatedResponse<ProductionOrderResponse> listOrders(String status, String plantCode,
                                                                   String dealer, int page, int size) {
        log.debug("Listing production orders: status={}, plant={}, dealer={}, page={}, size={}",
                status, plantCode, dealer, page, size);

        Page<ProductionOrder> orders = productionOrderRepository.searchOrders(
                status, plantCode, dealer,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdTs")));

        var content = orders.getContent().stream()
                .map(this::toProductionOrderResponse)
                .toList();

        return new PaginatedResponse<>("success", null, content,
                orders.getNumber(), orders.getTotalPages(), orders.getTotalElements(),
                LocalDateTime.now());
    }

    /**
     * Get a single production order by productionId.
     */
    public ProductionOrderResponse getOrder(String id) {
        log.debug("Getting production order id={}", id);
        ProductionOrder order = findOrderOrThrow(id);
        return toProductionOrderResponse(order);
    }

    /**
     * Update production order build status and build date.
     */
    @Transactional
    public ProductionOrderResponse updateOrder(String id, ProductionOrderRequest req) {
        log.info("PRODUCTION ORDER UPDATE: id={}", id);

        ProductionOrder order = findOrderOrThrow(id);

        if (req.getBuildDate() != null) {
            order.setBuildDate(req.getBuildDate());
        }
        order.setUpdatedTs(LocalDateTime.now());
        productionOrderRepository.save(order);

        log.info("Production order updated: id={}", id);
        return toProductionOrderResponse(order);
    }

    // ════════════════════════════════════════════════════════════════════
    // Allocation (PLIALLO0)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Allocate a production order to a dealer.
     * Vehicle must be in PR status.
     */
    @Transactional
    public ProductionOrderResponse allocateOrder(String id, ProductionAllocateRequest req) {
        log.info("PRODUCTION ALLOCATE: id={}, dealer={}", id, req.getAllocatedDealer());

        ProductionOrder order = findOrderOrThrow(id);

        // Validate vehicle is in PR status
        Vehicle vehicle = vehicleRepository.findById(order.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", order.getVin()));

        if (!"PR".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle " + order.getVin() + " cannot be allocated (status: " + vehicle.getVehicleStatus() + ")");
        }

        // Validate destination dealer exists
        if (!dealerRepository.existsById(req.getAllocatedDealer())) {
            throw new EntityNotFoundException("Dealer", req.getAllocatedDealer());
        }

        // Update order
        order.setAllocatedDealer(req.getAllocatedDealer());
        order.setAllocationDate(LocalDate.now());
        order.setBuildStatus("AL");
        order.setUpdatedTs(LocalDateTime.now());
        productionOrderRepository.save(order);

        // Update vehicle: dealerCode and status to AL
        vehicle.setDealerCode(req.getAllocatedDealer());
        vehicle.setVehicleStatus("AL");
        vehicle.setUpdatedTs(LocalDateTime.now());
        vehicleRepository.save(vehicle);

        // Process allocation in stock position
        stockPositionService.processAllocate(order.getVin(), req.getAllocatedDealer(),
                "SYSTEM", "Production order allocated: " + id);

        log.info("Production order allocated: id={}, dealer={}", id, req.getAllocatedDealer());
        return toProductionOrderResponse(order);
    }

    // ════════════════════════════════════════════════════════════════════
    // Shipments (PLISHPN0)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Create a new shipment.
     */
    @Transactional
    public ShipmentResponse createShipment(ShipmentRequest req) {
        log.info("SHIPMENT CREATE: carrier={}, origin={}, dest={}, mode={}",
                req.getCarrierCode(), req.getOriginPlant(), req.getDestDealer(), req.getTransportMode());

        String shipmentId = "SH" + System.currentTimeMillis();
        LocalDateTime now = LocalDateTime.now();

        // Calculate estimated arrival date based on transport mode
        LocalDate shipDate = req.getShipDate() != null ? req.getShipDate() : LocalDate.now();
        LocalDate estArrival = req.getEstArrivalDate();
        if (estArrival == null) {
            int transitDays = TRANSIT_DAYS.getOrDefault(req.getTransportMode(), DEFAULT_TRANSIT_DAYS);
            estArrival = shipDate.plusDays(transitDays);
        }

        Shipment shipment = Shipment.builder()
                .shipmentId(shipmentId)
                .carrierCode(req.getCarrierCode())
                .carrierName(req.getCarrierName())
                .originPlant(req.getOriginPlant())
                .destDealer(req.getDestDealer())
                .transportMode(req.getTransportMode())
                .vehicleCount((short) 0)
                .shipDate(shipDate)
                .estArrivalDate(estArrival)
                .shipmentStatus("CR")
                .createdTs(now)
                .updatedTs(now)
                .build();

        Shipment saved = shipmentRepository.save(shipment);
        log.info("Shipment created: id={}", saved.getShipmentId());
        return toShipmentResponse(saved, List.of());
    }

    /**
     * Search shipments with optional filters.
     */
    public PaginatedResponse<ShipmentResponse> listShipments(String status, String dealer,
                                                               String carrier, int page, int size) {
        log.debug("Listing shipments: status={}, dealer={}, carrier={}, page={}, size={}",
                status, dealer, carrier, page, size);

        Page<Shipment> shipments = shipmentRepository.searchShipments(
                status, dealer, carrier,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdTs")));

        var content = shipments.getContent().stream()
                .map(s -> toShipmentResponse(s, null))
                .toList();

        return new PaginatedResponse<>("success", null, content,
                shipments.getNumber(), shipments.getTotalPages(), shipments.getTotalElements(),
                LocalDateTime.now());
    }

    /**
     * Get a single shipment with its vehicle list.
     */
    public ShipmentResponse getShipment(String id) {
        log.debug("Getting shipment id={}", id);
        Shipment shipment = findShipmentOrThrow(id);
        List<ShipmentVehicle> vehicles = shipmentVehicleRepository.findByShipmentId(id);
        return toShipmentResponse(shipment, vehicles);
    }

    /**
     * Add a vehicle to a shipment. Shipment must be CR; vehicle must be AL.
     */
    @Transactional
    public ShipmentResponse addVehicleToShipment(String shipmentId, ShipmentVehicleRequest req) {
        log.info("SHIPMENT ADD VEHICLE: shipment={}, vin={}", shipmentId, req.getVin());

        Shipment shipment = findShipmentOrThrow(shipmentId);
        if (!"CR".equals(shipment.getShipmentStatus())) {
            throw new BusinessValidationException(
                    "Cannot add vehicles to shipment " + shipmentId + " (status: " + shipment.getShipmentStatus() + ")");
        }

        Vehicle vehicle = vehicleRepository.findById(req.getVin())
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", req.getVin()));
        if (!"AL".equals(vehicle.getVehicleStatus())) {
            throw new BusinessValidationException(
                    "Vehicle " + req.getVin() + " is not allocated (status: " + vehicle.getVehicleStatus() + ")");
        }

        ShipmentVehicle sv = ShipmentVehicle.builder()
                .shipmentId(shipmentId)
                .vin(req.getVin())
                .loadSequence(req.getLoadSequence())
                .build();
        shipmentVehicleRepository.save(sv);

        // Increment vehicle count
        shipment.setVehicleCount((short) (shipment.getVehicleCount() + 1));
        shipment.setUpdatedTs(LocalDateTime.now());
        shipmentRepository.save(shipment);

        List<ShipmentVehicle> vehicles = shipmentVehicleRepository.findByShipmentId(shipmentId);
        log.info("Vehicle added to shipment: shipment={}, vin={}, count={}",
                shipmentId, req.getVin(), shipment.getVehicleCount());
        return toShipmentResponse(shipment, vehicles);
    }

    /**
     * Dispatch a shipment. Status must be CR, vehicleCount > 0.
     * Updates all vehicles to SH status.
     */
    @Transactional
    public ShipmentResponse dispatchShipment(String shipmentId) {
        log.info("SHIPMENT DISPATCH: id={}", shipmentId);

        Shipment shipment = findShipmentOrThrow(shipmentId);
        if (!"CR".equals(shipment.getShipmentStatus())) {
            throw new BusinessValidationException(
                    "Shipment " + shipmentId + " cannot be dispatched (status: " + shipment.getShipmentStatus() + ")");
        }
        if (shipment.getVehicleCount() <= 0) {
            throw new BusinessValidationException(
                    "Shipment " + shipmentId + " has no vehicles to dispatch");
        }

        // Update all vehicles in shipment to SH
        List<ShipmentVehicle> svList = shipmentVehicleRepository.findByShipmentId(shipmentId);
        for (ShipmentVehicle sv : svList) {
            vehicleRepository.findById(sv.getVin()).ifPresent(v -> {
                v.setVehicleStatus("SH");
                v.setShipDate(LocalDate.now());
                v.setUpdatedTs(LocalDateTime.now());
                vehicleRepository.save(v);
            });
        }

        // Update shipment
        shipment.setShipmentStatus("DP");
        if (shipment.getShipDate() == null) {
            shipment.setShipDate(LocalDate.now());
        }
        shipment.setUpdatedTs(LocalDateTime.now());
        shipmentRepository.save(shipment);

        log.info("Shipment dispatched: id={}, vehicleCount={}", shipmentId, shipment.getVehicleCount());
        return toShipmentResponse(shipment, svList);
    }

    // ════════════════════════════════════════════════════════════════════
    // Transit (PLITRNS0)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Add a transit status update for a VIN.
     */
    @Transactional
    public TransitStatusResponse addTransitStatus(TransitStatusRequest req) {
        log.info("TRANSIT STATUS: vin={}, status={}, location={}", req.getVin(), req.getStatusCode(), req.getLocationDesc());

        // Get next sequence number
        int nextSeq = transitStatusRepository.findTopByVinOrderByStatusSeqDesc(req.getVin())
                .map(ts -> ts.getStatusSeq() + 1)
                .orElse(1);

        LocalDateTime now = LocalDateTime.now();

        TransitStatus status = TransitStatus.builder()
                .vin(req.getVin())
                .statusSeq(nextSeq)
                .locationDesc(req.getLocationDesc())
                .statusCode(req.getStatusCode())
                .ediRefNum(req.getEdiRefNum())
                .statusTs(now)
                .receivedTs(now)
                .build();
        transitStatusRepository.save(status);

        // Update shipment status to match transit status code
        shipmentVehicleRepository.findByVin(req.getVin()).ifPresent(sv -> {
            shipmentRepository.findById(sv.getShipmentId()).ifPresent(shipment -> {
                shipment.setShipmentStatus(req.getStatusCode());
                shipment.setUpdatedTs(now);
                if ("DL".equals(req.getStatusCode())) {
                    shipment.setActArrivalDate(LocalDate.now());
                }
                shipmentRepository.save(shipment);
            });
        });

        // If delivered, update vehicle status
        if ("DL".equals(req.getStatusCode())) {
            vehicleRepository.findById(req.getVin()).ifPresent(v -> {
                v.setVehicleStatus("DL");
                v.setUpdatedTs(now);
                vehicleRepository.save(v);
            });
        }

        log.info("Transit status added: vin={}, seq={}, code={}", req.getVin(), nextSeq, req.getStatusCode());
        return toTransitStatusResponse(status);
    }

    /**
     * Get transit history for a VIN.
     */
    public List<TransitStatusResponse> getTransitHistory(String vin) {
        log.debug("Getting transit history for vin={}", vin);
        return transitStatusRepository.findByVinOrderByStatusSeqAsc(vin).stream()
                .map(this::toTransitStatusResponse)
                .toList();
    }

    // ════════════════════════════════════════════════════════════════════
    // Delivery (PLIDLVR0)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Deliver a shipment. Marks all vehicles as DL, schedules PDI, updates stock positions.
     */
    @Transactional
    public ShipmentResponse deliverShipment(String shipmentId, ShipmentDeliverRequest req) {
        log.info("SHIPMENT DELIVER: id={}, receivedBy={}", shipmentId, req.getReceivedBy());

        Shipment shipment = findShipmentOrThrow(shipmentId);

        List<ShipmentVehicle> svList = shipmentVehicleRepository.findByShipmentId(shipmentId);
        LocalDateTime now = LocalDateTime.now();

        for (ShipmentVehicle sv : svList) {
            vehicleRepository.findById(sv.getVin()).ifPresent(v -> {
                // Update vehicle to delivered
                v.setVehicleStatus("DL");
                v.setReceiveDate(LocalDate.now());
                v.setUpdatedTs(now);
                vehicleRepository.save(v);

                // Schedule PDI (42 checklist items, status SC)
                PdiSchedule pdi = PdiSchedule.builder()
                        .vin(sv.getVin())
                        .dealerCode(shipment.getDestDealer())
                        .scheduledDate(LocalDate.now().plusDays(1))
                        .pdiStatus("SC")
                        .checklistItems((short) 42)
                        .itemsPassed((short) 0)
                        .itemsFailed((short) 0)
                        .build();
                pdiScheduleRepository.save(pdi);

                // Update stock position — receive vehicle into dealer inventory
                stockPositionService.processReceive(sv.getVin(), shipment.getDestDealer(),
                        req.getReceivedBy(), "Shipment delivered: " + shipmentId);
            });
        }

        // Update shipment
        shipment.setShipmentStatus("DL");
        shipment.setActArrivalDate(LocalDate.now());
        shipment.setUpdatedTs(now);
        shipmentRepository.save(shipment);

        log.info("Shipment delivered: id={}, vehicles={}", shipmentId, svList.size());
        return toShipmentResponse(shipment, svList);
    }

    // ════════════════════════════════════════════════════════════════════
    // PDI (PLIVPDS0)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Schedule a PDI inspection.
     */
    @Transactional
    public PdiScheduleResponse schedulePdi(PdiScheduleRequest req) {
        log.info("PDI SCHEDULE: vin={}, dealer={}, date={}", req.getVin(), req.getDealerCode(), req.getScheduledDate());

        PdiSchedule pdi = PdiSchedule.builder()
                .vin(req.getVin())
                .dealerCode(req.getDealerCode())
                .scheduledDate(req.getScheduledDate())
                .technicianId(req.getTechnicianId())
                .pdiStatus("SC")
                .checklistItems((short) 42)
                .itemsPassed((short) 0)
                .itemsFailed((short) 0)
                .build();

        PdiSchedule saved = pdiScheduleRepository.save(pdi);
        log.info("PDI scheduled: id={}, vin={}", saved.getPdiId(), saved.getVin());
        return toPdiResponse(saved);
    }

    /**
     * List PDI schedules for a dealer, optionally filtered by status.
     */
    public PaginatedResponse<PdiScheduleResponse> listPdiSchedules(String dealerCode, String status,
                                                                     int page, int size) {
        log.debug("Listing PDI schedules: dealer={}, status={}, page={}, size={}", dealerCode, status, page, size);

        Page<PdiSchedule> pdis;
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "scheduledDate"));
        if (status != null && !status.isBlank()) {
            pdis = pdiScheduleRepository.findByDealerCodeAndPdiStatus(dealerCode, status, pageRequest);
        } else {
            pdis = pdiScheduleRepository.findByDealerCode(dealerCode, pageRequest);
        }

        var content = pdis.getContent().stream()
                .map(this::toPdiResponse)
                .toList();

        return new PaginatedResponse<>("success", null, content,
                pdis.getNumber(), pdis.getTotalPages(), pdis.getTotalElements(),
                LocalDateTime.now());
    }

    /**
     * Start a PDI inspection. Status must be SC.
     */
    @Transactional
    public PdiScheduleResponse startPdi(int pdiId, String technicianId) {
        log.info("PDI START: id={}, technician={}", pdiId, technicianId);

        PdiSchedule pdi = findPdiOrThrow(pdiId);
        if (!"SC".equals(pdi.getPdiStatus())) {
            throw new BusinessValidationException(
                    "PDI " + pdiId + " cannot be started (status: " + pdi.getPdiStatus() + ")");
        }

        pdi.setPdiStatus("IP");
        pdi.setTechnicianId(technicianId);
        pdiScheduleRepository.save(pdi);

        log.info("PDI started: id={}", pdiId);
        return toPdiResponse(pdi);
    }

    /**
     * Complete a PDI inspection. Status must be IP.
     * Updates vehicle to pdiComplete=Y, status=AV.
     */
    @Transactional
    public PdiScheduleResponse completePdi(int pdiId, PdiCompleteRequest req) {
        log.info("PDI COMPLETE: id={}, passed={}, failed={}", pdiId, req.getItemsPassed(), req.getItemsFailed());

        PdiSchedule pdi = findPdiOrThrow(pdiId);
        if (!"IP".equals(pdi.getPdiStatus())) {
            throw new BusinessValidationException(
                    "PDI " + pdiId + " cannot be completed (status: " + pdi.getPdiStatus() + ")");
        }

        pdi.setPdiStatus("CM");
        pdi.setItemsPassed(req.getItemsPassed());
        pdi.setItemsFailed(req.getItemsFailed());
        pdi.setNotes(req.getNotes());
        pdi.setCompletedTs(LocalDateTime.now());
        pdiScheduleRepository.save(pdi);

        // Update vehicle: PDI complete, status to AV
        vehicleRepository.findById(pdi.getVin()).ifPresent(v -> {
            v.setPdiComplete("Y");
            v.setPdiDate(LocalDate.now());
            v.setVehicleStatus("AV");
            v.setUpdatedTs(LocalDateTime.now());
            vehicleRepository.save(v);
        });

        // Process receive into stock (makes vehicle available in stock position)
        stockPositionService.processReceive(pdi.getVin(), pdi.getDealerCode(),
                pdi.getTechnicianId(), "PDI completed: #" + pdiId);

        log.info("PDI completed: id={}", pdiId);
        return toPdiResponse(pdi);
    }

    /**
     * Fail a PDI inspection. Status must be IP.
     */
    @Transactional
    public PdiScheduleResponse failPdi(int pdiId, PdiCompleteRequest req) {
        log.info("PDI FAIL: id={}, passed={}, failed={}", pdiId, req.getItemsPassed(), req.getItemsFailed());

        PdiSchedule pdi = findPdiOrThrow(pdiId);
        if (!"IP".equals(pdi.getPdiStatus())) {
            throw new BusinessValidationException(
                    "PDI " + pdiId + " cannot be failed (status: " + pdi.getPdiStatus() + ")");
        }

        pdi.setPdiStatus("FL");
        pdi.setItemsPassed(req.getItemsPassed());
        pdi.setItemsFailed(req.getItemsFailed());
        pdi.setNotes(req.getNotes());
        pdi.setCompletedTs(LocalDateTime.now());
        pdiScheduleRepository.save(pdi);

        log.info("PDI failed: id={}", pdiId);
        return toPdiResponse(pdi);
    }

    // ════════════════════════════════════════════════════════════════════
    // ETA (PLIETA00)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Calculate ETA for a vehicle in transit.
     */
    public EtaResponse calculateEta(String vin) {
        log.debug("Calculating ETA for vin={}", vin);

        Vehicle vehicle = vehicleRepository.findById(vin)
                .orElseThrow(() -> new EntityNotFoundException("Vehicle", vin));

        // Find the shipment for this VIN
        ShipmentVehicle sv = shipmentVehicleRepository.findByVin(vin)
                .orElseThrow(() -> new BusinessValidationException(
                        "No shipment found for VIN " + vin));

        Shipment shipment = shipmentRepository.findById(sv.getShipmentId())
                .orElseThrow(() -> new EntityNotFoundException("Shipment", sv.getShipmentId()));

        // Get latest transit status for current location
        String currentLocation = transitStatusRepository.findTopByVinOrderByStatusSeqDesc(vin)
                .map(TransitStatus::getLocationDesc)
                .orElse(shipment.getOriginPlant());

        // Calculate days in transit and remaining
        LocalDate shipDate = shipment.getShipDate() != null ? shipment.getShipDate() : LocalDate.now();
        int daysInTransit = (int) ChronoUnit.DAYS.between(shipDate, LocalDate.now());
        int daysRemaining = shipment.getEstArrivalDate() != null
                ? Math.max(0, (int) ChronoUnit.DAYS.between(LocalDate.now(), shipment.getEstArrivalDate()))
                : 0;

        return EtaResponse.builder()
                .vin(vin)
                .vehicleDesc(buildVehicleDesc(vehicle))
                .shipmentId(shipment.getShipmentId())
                .currentLocation(currentLocation)
                .daysInTransit(daysInTransit)
                .estimatedDaysRemaining(daysRemaining)
                .estArrivalDate(shipment.getEstArrivalDate())
                .transportMode(shipment.getTransportMode())
                .build();
    }

    // ════════════════════════════════════════════════════════════════════
    // Reconciliation (PLIRECON)
    // ════════════════════════════════════════════════════════════════════

    /**
     * Reconcile production orders against vehicles.
     * Identifies count by status and exception conditions.
     */
    public ProductionReconciliationResponse reconcile(String plantCode, Short modelYear, String makeCode) {
        log.info("RECONCILE: plant={}, year={}, make={}", plantCode, modelYear, makeCode);

        long totalProduced = productionOrderRepository.countByBuildStatus("PR");
        long totalAllocated = productionOrderRepository.countByBuildStatus("AL");
        long totalShipped = productionOrderRepository.countByBuildStatus("SH");
        long totalDelivered = productionOrderRepository.countByBuildStatus("CM");

        List<ProductionReconciliationResponse.ReconciliationException> exceptions = new ArrayList<>();

        // Find all orders for analysis
        Page<ProductionOrder> allOrders = productionOrderRepository.searchOrders(
                null, plantCode, null, PageRequest.of(0, 10000));

        for (ProductionOrder order : allOrders.getContent()) {
            // Filter by modelYear and makeCode if provided
            if (modelYear != null && !modelYear.equals(order.getModelYear())) continue;
            if (makeCode != null && !makeCode.equals(order.getMakeCode())) continue;

            Vehicle vehicle = vehicleRepository.findById(order.getVin()).orElse(null);
            int daysSinceBuild = order.getBuildDate() != null
                    ? (int) ChronoUnit.DAYS.between(order.getBuildDate(), LocalDate.now())
                    : 0;

            // NV: No vehicle record
            if (vehicle == null) {
                exceptions.add(ProductionReconciliationResponse.ReconciliationException.builder()
                        .vin(order.getVin())
                        .productionStatus(order.getBuildStatus())
                        .vehicleStatus("NONE")
                        .reasonCode("NV")
                        .reasonDesc("No vehicle record found for production order")
                        .daysSinceBuild(daysSinceBuild)
                        .plantCode(order.getPlantCode())
                        .build());
                continue;
            }

            // NS: Allocated > 14 days but not shipped
            if ("AL".equals(order.getBuildStatus()) && order.getAllocationDate() != null) {
                long daysSinceAlloc = ChronoUnit.DAYS.between(order.getAllocationDate(), LocalDate.now());
                if (daysSinceAlloc > 14 && !"SH".equals(vehicle.getVehicleStatus())) {
                    exceptions.add(ProductionReconciliationResponse.ReconciliationException.builder()
                            .vin(order.getVin())
                            .productionStatus(order.getBuildStatus())
                            .vehicleStatus(vehicle.getVehicleStatus())
                            .reasonCode("NS")
                            .reasonDesc("Allocated " + daysSinceAlloc + " days ago, not yet shipped")
                            .daysSinceBuild(daysSinceBuild)
                            .plantCode(order.getPlantCode())
                            .build());
                }
            }

            // ND: Shipped > 21 days but not delivered
            if ("SH".equals(order.getBuildStatus()) && vehicle.getShipDate() != null) {
                long daysSinceShip = ChronoUnit.DAYS.between(vehicle.getShipDate(), LocalDate.now());
                if (daysSinceShip > 21 && !"DL".equals(vehicle.getVehicleStatus())
                        && !"AV".equals(vehicle.getVehicleStatus())) {
                    exceptions.add(ProductionReconciliationResponse.ReconciliationException.builder()
                            .vin(order.getVin())
                            .productionStatus(order.getBuildStatus())
                            .vehicleStatus(vehicle.getVehicleStatus())
                            .reasonCode("ND")
                            .reasonDesc("Shipped " + daysSinceShip + " days ago, not yet delivered")
                            .daysSinceBuild(daysSinceBuild)
                            .plantCode(order.getPlantCode())
                            .build());
                }
            }

            // SM: Status mismatch between production order and vehicle
            if (!isStatusConsistent(order.getBuildStatus(), vehicle.getVehicleStatus())) {
                exceptions.add(ProductionReconciliationResponse.ReconciliationException.builder()
                        .vin(order.getVin())
                        .productionStatus(order.getBuildStatus())
                        .vehicleStatus(vehicle.getVehicleStatus())
                        .reasonCode("SM")
                        .reasonDesc("Status mismatch: order=" + order.getBuildStatus()
                                + ", vehicle=" + vehicle.getVehicleStatus())
                        .daysSinceBuild(daysSinceBuild)
                        .plantCode(order.getPlantCode())
                        .build());
            }
        }

        log.info("RECONCILE COMPLETE: produced={}, allocated={}, shipped={}, delivered={}, exceptions={}",
                totalProduced, totalAllocated, totalShipped, totalDelivered, exceptions.size());

        return ProductionReconciliationResponse.builder()
                .totalProduced(totalProduced)
                .totalAllocated(totalAllocated)
                .totalShipped(totalShipped)
                .totalDelivered(totalDelivered)
                .exceptions(exceptions)
                .build();
    }

    // ── Private helpers ──────────────────────────────────────────────────

    private ProductionOrder findOrderOrThrow(String id) {
        return productionOrderRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("ProductionOrder", id));
    }

    private Shipment findShipmentOrThrow(String id) {
        return shipmentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Shipment", id));
    }

    private PdiSchedule findPdiOrThrow(int pdiId) {
        return pdiScheduleRepository.findById(pdiId)
                .orElseThrow(() -> new EntityNotFoundException("PdiSchedule", String.valueOf(pdiId)));
    }

    private boolean isStatusConsistent(String buildStatus, String vehicleStatus) {
        return switch (buildStatus) {
            case "PR" -> "PR".equals(vehicleStatus);
            case "AL" -> "AL".equals(vehicleStatus);
            case "SH" -> "SH".equals(vehicleStatus);
            case "CM" -> "DL".equals(vehicleStatus) || "AV".equals(vehicleStatus) || "SD".equals(vehicleStatus);
            default -> true;
        };
    }

    private String buildVehicleDesc(Vehicle vehicle) {
        if (vehicle == null) return "Unknown";
        return vehicle.getModelYear() + " " + vehicle.getMakeCode() + " " + vehicle.getModelCode();
    }

    private ProductionOrderResponse toProductionOrderResponse(ProductionOrder order) {
        Vehicle vehicle = vehicleRepository.findById(order.getVin()).orElse(null);
        return ProductionOrderResponse.builder()
                .productionId(order.getProductionId())
                .vin(order.getVin())
                .modelYear(order.getModelYear())
                .makeCode(order.getMakeCode())
                .modelCode(order.getModelCode())
                .vehicleDesc(buildVehicleDesc(vehicle))
                .plantCode(order.getPlantCode())
                .buildDate(order.getBuildDate())
                .buildStatus(order.getBuildStatus())
                .buildStatusName(BUILD_STATUS_NAMES.getOrDefault(order.getBuildStatus(), order.getBuildStatus()))
                .allocatedDealer(order.getAllocatedDealer())
                .allocationDate(order.getAllocationDate())
                .createdTs(order.getCreatedTs())
                .updatedTs(order.getUpdatedTs())
                .build();
    }

    private ShipmentResponse toShipmentResponse(Shipment shipment, List<ShipmentVehicle> vehicles) {
        List<ShipmentVehicleResponse> vehicleResponses = null;
        if (vehicles != null) {
            vehicleResponses = vehicles.stream()
                    .map(sv -> {
                        Vehicle v = vehicleRepository.findById(sv.getVin()).orElse(null);
                        return ShipmentVehicleResponse.builder()
                                .shipmentId(sv.getShipmentId())
                                .vin(sv.getVin())
                                .vehicleDesc(buildVehicleDesc(v))
                                .loadSequence(sv.getLoadSequence())
                                .build();
                    })
                    .toList();
        }

        return ShipmentResponse.builder()
                .shipmentId(shipment.getShipmentId())
                .carrierCode(shipment.getCarrierCode())
                .carrierName(shipment.getCarrierName())
                .originPlant(shipment.getOriginPlant())
                .destDealer(shipment.getDestDealer())
                .transportMode(shipment.getTransportMode())
                .vehicleCount(shipment.getVehicleCount())
                .shipDate(shipment.getShipDate())
                .estArrivalDate(shipment.getEstArrivalDate())
                .actArrivalDate(shipment.getActArrivalDate())
                .shipmentStatus(shipment.getShipmentStatus())
                .statusName(SHIPMENT_STATUS_NAMES.getOrDefault(shipment.getShipmentStatus(), shipment.getShipmentStatus()))
                .vehicles(vehicleResponses)
                .createdTs(shipment.getCreatedTs())
                .updatedTs(shipment.getUpdatedTs())
                .build();
    }

    private TransitStatusResponse toTransitStatusResponse(TransitStatus status) {
        String statusName = switch (status.getStatusCode()) {
            case "DP" -> "Dispatched";
            case "IT" -> "In Transit";
            case "DL" -> "Delivered";
            case "CR" -> "Created";
            default -> status.getStatusCode();
        };

        return TransitStatusResponse.builder()
                .vin(status.getVin())
                .statusSeq(status.getStatusSeq())
                .locationDesc(status.getLocationDesc())
                .statusCode(status.getStatusCode())
                .statusName(statusName)
                .ediRefNum(status.getEdiRefNum())
                .statusTs(status.getStatusTs())
                .receivedTs(status.getReceivedTs())
                .build();
    }

    private PdiScheduleResponse toPdiResponse(PdiSchedule pdi) {
        Vehicle vehicle = vehicleRepository.findById(pdi.getVin()).orElse(null);

        BigDecimal passRate = null;
        if (pdi.getItemsPassed() > 0 || pdi.getItemsFailed() > 0) {
            int total = pdi.getItemsPassed() + pdi.getItemsFailed();
            if (total > 0) {
                passRate = BigDecimal.valueOf(pdi.getItemsPassed())
                        .multiply(BigDecimal.valueOf(100))
                        .divide(BigDecimal.valueOf(total), 2, RoundingMode.HALF_UP);
            }
        }

        return PdiScheduleResponse.builder()
                .pdiId(pdi.getPdiId())
                .vin(pdi.getVin())
                .vehicleDesc(buildVehicleDesc(vehicle))
                .dealerCode(pdi.getDealerCode())
                .scheduledDate(pdi.getScheduledDate())
                .technicianId(pdi.getTechnicianId())
                .pdiStatus(pdi.getPdiStatus())
                .statusName(PDI_STATUS_NAMES.getOrDefault(pdi.getPdiStatus(), pdi.getPdiStatus()))
                .checklistItems(pdi.getChecklistItems())
                .itemsPassed(pdi.getItemsPassed())
                .itemsFailed(pdi.getItemsFailed())
                .notes(pdi.getNotes())
                .completedTs(pdi.getCompletedTs())
                .passRate(passRate)
                .build();
    }
}
