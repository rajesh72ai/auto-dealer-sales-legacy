package com.autosales.modules.vehicle.controller;

import com.autosales.common.security.DealerScoped;
import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.service.VehicleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for vehicle inventory management.
 * Port of VEHINQ00.cbl — vehicle inquiry
 *        VEHLST00.cbl — vehicle list/search
 *        VEHUPD00.cbl — vehicle update/status transition
 *        VEHRCV00.cbl — vehicle receive into stock
 *        VEHALL00.cbl — vehicle factory allocation
 *        VEHAGE00.cbl — vehicle aging report
 */
@RestController
@RequestMapping("/api/vehicles")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','OPERATOR','AGENT_SERVICE')")
@Slf4j
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleService vehicleService;
    private final ResponseFormatter responseFormatter;

    // ── Get Single Vehicle ──────────────────────────────────────────

    @GetMapping("/{vin}")
    public ResponseEntity<ApiResponse<VehicleResponse>> getVehicle(@PathVariable String vin) {
        log.info("GET /api/vehicles/{}", vin);
        VehicleResponse response = vehicleService.getVehicle(vin);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // ── List / Search Vehicles ──────────────────────────────────────

    @GetMapping
    @DealerScoped
    public ResponseEntity<PaginatedResponse<VehicleListResponse>> listVehicles(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Short modelYear,
            @RequestParam(required = false) String makeCode,
            @RequestParam(required = false) String modelCode,
            @RequestParam(required = false) String color,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/vehicles — dealer: {}, status: {}, year: {}, make: {}, model: {}, color: {}, page: {}, size: {}",
                dealerCode, status, modelYear, makeCode, modelCode, color, page, size);
        PaginatedResponse<VehicleListResponse> result = vehicleService.listVehicles(
                dealerCode, status, modelYear, makeCode, modelCode, color, page, size);
        return ResponseEntity.ok(result);
    }

    // ── Update Vehicle ──────────────────────────────────────────────

    @PutMapping("/{vin}")
    public ResponseEntity<ApiResponse<VehicleResponse>> updateVehicle(
            @PathVariable String vin,
            @Valid @RequestBody VehicleUpdateRequest request) {
        log.info("PUT /api/vehicles/{} — status: {}", vin, request.getVehicleStatus());
        VehicleResponse response = vehicleService.updateVehicle(vin, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Vehicle updated successfully"));
    }

    // ── Receive Vehicle ─────────────────────────────────────────────

    @PostMapping("/{vin}/receive")
    public ResponseEntity<ApiResponse<VehicleResponse>> receiveVehicle(
            @PathVariable String vin,
            @Valid @RequestBody VehicleReceiveRequest request) {
        log.info("POST /api/vehicles/{}/receive", vin);
        VehicleResponse response = vehicleService.receiveVehicle(vin, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Vehicle received into inventory"));
    }

    // ── Allocate Vehicle ────────────────────────────────────────────

    @PostMapping("/{vin}/allocate")
    public ResponseEntity<ApiResponse<VehicleResponse>> allocateVehicle(
            @PathVariable String vin,
            @Valid @RequestBody VehicleAllocateRequest request) {
        log.info("POST /api/vehicles/{}/allocate", vin);
        VehicleResponse response = vehicleService.allocateVehicle(vin, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Vehicle allocated successfully"));
    }

    // ── Aging Report ────────────────────────────────────────────────

    @GetMapping("/aging")
    public ResponseEntity<ApiResponse<AgingReportResponse>> getAgingReport(
            @RequestParam String dealerCode) {
        log.info("GET /api/vehicles/aging — dealer: {}", dealerCode);
        AgingReportResponse response = vehicleService.getAgingReport(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // ── Status History ──────────────────────────────────────────────

    @GetMapping("/{vin}/history")
    public ResponseEntity<ApiResponse<List<VehicleHistoryEntry>>> getStatusHistory(
            @PathVariable String vin) {
        log.info("GET /api/vehicles/{}/history", vin);
        List<VehicleHistoryEntry> response = vehicleService.getStatusHistory(vin);
        return ResponseEntity.ok(responseFormatter.success(response));
    }
}
