package com.autosales.modules.vehicle.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.service.ProductionLogisticsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for production logistics operations.
 * Port of 8 PLI programs: PLIPROD0, PLISHPN0, PLITRNS0, PLIDLVR0,
 * PLIVPDS0, PLIALLO0, PLIETA00, PLIRECON.
 *
 * <p>Consolidates production orders, shipments, transit tracking, delivery,
 * PDI scheduling, ETA calculation, and reconciliation into a single controller.</p>
 */
@RestController
@RequestMapping("/api/production")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class ProductionLogisticsController {

    private final ProductionLogisticsService service;
    private final ResponseFormatter responseFormatter;

    // ════════════════════════════════════════════════════════════════════
    // Production Orders
    // ════════════════════════════════════════════════════════════════════

    @PostMapping("/orders")
    public ResponseEntity<ApiResponse<ProductionOrderResponse>> createOrder(
            @Valid @RequestBody ProductionOrderRequest request) {
        log.info("POST /api/production/orders — vin={}, plant={}", request.getVin(), request.getPlantCode());
        ProductionOrderResponse response = service.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Production order created successfully"));
    }

    @GetMapping("/orders")
    public ResponseEntity<PaginatedResponse<ProductionOrderResponse>> listOrders(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String plantCode,
            @RequestParam(required = false) String dealer,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/production/orders — status={}, plant={}, dealer={}, page={}, size={}",
                status, plantCode, dealer, page, size);
        PaginatedResponse<ProductionOrderResponse> response = service.listOrders(status, plantCode, dealer, page, size);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/orders/{id}")
    public ResponseEntity<ApiResponse<ProductionOrderResponse>> getOrder(@PathVariable String id) {
        log.info("GET /api/production/orders/{}", id);
        ProductionOrderResponse response = service.getOrder(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PutMapping("/orders/{id}")
    public ResponseEntity<ApiResponse<ProductionOrderResponse>> updateOrder(
            @PathVariable String id,
            @Valid @RequestBody ProductionOrderRequest request) {
        log.info("PUT /api/production/orders/{}", id);
        ProductionOrderResponse response = service.updateOrder(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Production order updated successfully"));
    }

    @PostMapping("/orders/{id}/allocate")
    public ResponseEntity<ApiResponse<ProductionOrderResponse>> allocateOrder(
            @PathVariable String id,
            @Valid @RequestBody ProductionAllocateRequest request) {
        log.info("POST /api/production/orders/{}/allocate — dealer={}", id, request.getAllocatedDealer());
        ProductionOrderResponse response = service.allocateOrder(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Production order allocated successfully"));
    }

    // ════════════════════════════════════════════════════════════════════
    // Shipments
    // ════════════════════════════════════════════════════════════════════

    @PostMapping("/shipments")
    public ResponseEntity<ApiResponse<ShipmentResponse>> createShipment(
            @Valid @RequestBody ShipmentRequest request) {
        log.info("POST /api/production/shipments — carrier={}, dest={}", request.getCarrierCode(), request.getDestDealer());
        ShipmentResponse response = service.createShipment(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Shipment created successfully"));
    }

    @GetMapping("/shipments")
    public ResponseEntity<PaginatedResponse<ShipmentResponse>> listShipments(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String dealer,
            @RequestParam(required = false) String carrier,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/production/shipments — status={}, dealer={}, carrier={}, page={}, size={}",
                status, dealer, carrier, page, size);
        PaginatedResponse<ShipmentResponse> response = service.listShipments(status, dealer, carrier, page, size);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/shipments/{id}")
    public ResponseEntity<ApiResponse<ShipmentResponse>> getShipment(@PathVariable String id) {
        log.info("GET /api/production/shipments/{}", id);
        ShipmentResponse response = service.getShipment(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping("/shipments/{id}/vehicles")
    public ResponseEntity<ApiResponse<ShipmentResponse>> addVehicleToShipment(
            @PathVariable String id,
            @Valid @RequestBody ShipmentVehicleRequest request) {
        log.info("POST /api/production/shipments/{}/vehicles — vin={}", id, request.getVin());
        ShipmentResponse response = service.addVehicleToShipment(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Vehicle added to shipment successfully"));
    }

    @PostMapping("/shipments/{id}/dispatch")
    public ResponseEntity<ApiResponse<ShipmentResponse>> dispatchShipment(@PathVariable String id) {
        log.info("POST /api/production/shipments/{}/dispatch", id);
        ShipmentResponse response = service.dispatchShipment(id);
        return ResponseEntity.ok(responseFormatter.success(response, "Shipment dispatched successfully"));
    }

    @PostMapping("/shipments/{id}/deliver")
    public ResponseEntity<ApiResponse<ShipmentResponse>> deliverShipment(
            @PathVariable String id,
            @Valid @RequestBody ShipmentDeliverRequest request) {
        log.info("POST /api/production/shipments/{}/deliver", id);
        ShipmentResponse response = service.deliverShipment(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Shipment delivered successfully"));
    }

    // ════════════════════════════════════════════════════════════════════
    // Transit
    // ════════════════════════════════════════════════════════════════════

    @GetMapping("/transit/{vin}")
    public ResponseEntity<ApiResponse<List<TransitStatusResponse>>> getTransitHistory(
            @PathVariable String vin) {
        log.info("GET /api/production/transit/{}", vin);
        List<TransitStatusResponse> history = service.getTransitHistory(vin);
        return ResponseEntity.ok(responseFormatter.success(history));
    }

    @PostMapping("/transit")
    public ResponseEntity<ApiResponse<TransitStatusResponse>> addTransitStatus(
            @Valid @RequestBody TransitStatusRequest request) {
        log.info("POST /api/production/transit — vin={}, status={}", request.getVin(), request.getStatusCode());
        TransitStatusResponse response = service.addTransitStatus(request);
        return ResponseEntity.ok(responseFormatter.success(response, "Transit status added successfully"));
    }

    @GetMapping("/transit/{vin}/eta")
    public ResponseEntity<ApiResponse<EtaResponse>> calculateEta(@PathVariable String vin) {
        log.info("GET /api/production/transit/{}/eta", vin);
        EtaResponse response = service.calculateEta(vin);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // ════════════════════════════════════════════════════════════════════
    // PDI
    // ════════════════════════════════════════════════════════════════════

    @PostMapping("/pdi/schedule")
    public ResponseEntity<ApiResponse<PdiScheduleResponse>> schedulePdi(
            @Valid @RequestBody PdiScheduleRequest request) {
        log.info("POST /api/production/pdi/schedule — vin={}, dealer={}", request.getVin(), request.getDealerCode());
        PdiScheduleResponse response = service.schedulePdi(request);
        return ResponseEntity.ok(responseFormatter.success(response, "PDI scheduled successfully"));
    }

    @GetMapping("/pdi/schedule")
    public ResponseEntity<PaginatedResponse<PdiScheduleResponse>> listPdiSchedules(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/production/pdi/schedule — dealer={}, status={}, page={}, size={}",
                dealerCode, status, page, size);
        PaginatedResponse<PdiScheduleResponse> response = service.listPdiSchedules(dealerCode, status, page, size);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/pdi/{pdiId}/start")
    public ResponseEntity<ApiResponse<PdiScheduleResponse>> startPdi(
            @PathVariable int pdiId,
            @RequestParam String technicianId) {
        log.info("POST /api/production/pdi/{}/start — technician={}", pdiId, technicianId);
        PdiScheduleResponse response = service.startPdi(pdiId, technicianId);
        return ResponseEntity.ok(responseFormatter.success(response, "PDI started successfully"));
    }

    @PostMapping("/pdi/{pdiId}/complete")
    public ResponseEntity<ApiResponse<PdiScheduleResponse>> completePdi(
            @PathVariable int pdiId,
            @Valid @RequestBody PdiCompleteRequest request) {
        log.info("POST /api/production/pdi/{}/complete", pdiId);
        PdiScheduleResponse response = service.completePdi(pdiId, request);
        return ResponseEntity.ok(responseFormatter.success(response, "PDI completed successfully"));
    }

    @PostMapping("/pdi/{pdiId}/fail")
    public ResponseEntity<ApiResponse<PdiScheduleResponse>> failPdi(
            @PathVariable int pdiId,
            @Valid @RequestBody PdiCompleteRequest request) {
        log.info("POST /api/production/pdi/{}/fail", pdiId);
        PdiScheduleResponse response = service.failPdi(pdiId, request);
        return ResponseEntity.ok(responseFormatter.success(response, "PDI failed — inspection results recorded"));
    }

    // ════════════════════════════════════════════════════════════════════
    // Reconciliation
    // ════════════════════════════════════════════════════════════════════

    @PostMapping("/reconcile")
    public ResponseEntity<ApiResponse<ProductionReconciliationResponse>> reconcile(
            @RequestParam(required = false) String plantCode,
            @RequestParam(required = false) Short modelYear,
            @RequestParam(required = false) String makeCode) {
        log.info("POST /api/production/reconcile — plant={}, year={}, make={}", plantCode, modelYear, makeCode);
        ProductionReconciliationResponse response = service.reconcile(plantCode, modelYear, makeCode);
        return ResponseEntity.ok(responseFormatter.success(response, "Reconciliation completed"));
    }
}
