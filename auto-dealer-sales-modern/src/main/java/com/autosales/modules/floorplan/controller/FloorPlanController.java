package com.autosales.modules.floorplan.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.floorplan.dto.*;
import com.autosales.modules.floorplan.service.FloorPlanReportService;
import com.autosales.modules.floorplan.service.FloorPlanService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for floor plan inventory financing.
 * Port of FPADD00.cbl  — floor plan vehicle add
 *        FPINQ00.cbl  — floor plan inquiry / list
 *        FPPAY00.cbl  — floor plan payoff
 *        FPINT00.cbl  — floor plan interest accrual
 *        FPLND00.cbl  — floor plan lender inquiry
 *        FPEXP00.cbl  — floor plan exposure report
 */
@RestController
@RequestMapping("/api/floorplan")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','OPERATOR','AGENT_SERVICE')")
@Slf4j
@RequiredArgsConstructor
public class FloorPlanController {

    private final FloorPlanService floorPlanService;
    private final FloorPlanReportService floorPlanReportService;
    private final ResponseFormatter responseFormatter;

    // -- List Floor Plan Vehicles ---------------------------------------------

    @GetMapping("/vehicles")
    public ResponseEntity<PaginatedResponse<FloorPlanVehicleResponse>> listFloorPlanVehicles(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String lenderId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing floor plan vehicles - dealer: {}, status: {}, lender: {}, page: {}, size: {}",
                dealerCode, status, lenderId, page, size);
        PaginatedResponse<FloorPlanVehicleResponse> result =
                floorPlanService.listFloorPlanVehicles(dealerCode, status, lenderId, page, Math.min(size, 100));
        return ResponseEntity.ok(result);
    }

    // -- Add Vehicle to Floor Plan --------------------------------------------

    @PostMapping("/vehicles")
    public ResponseEntity<ApiResponse<FloorPlanVehicleResponse>> addVehicleToFloorPlan(
            @Valid @RequestBody FloorPlanAddRequest request) {
        log.info("Adding vehicle to floor plan - VIN: {}, dealer: {}, lender: {}",
                request.getVin(), request.getDealerCode(), request.getLenderId());
        FloorPlanVehicleResponse response = floorPlanService.addVehicleToFloorPlan(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Vehicle added to floor plan successfully"));
    }

    // -- Payoff Floor Plan ----------------------------------------------------

    @PostMapping("/vehicles/payoff")
    public ResponseEntity<ApiResponse<FloorPlanPayoffResponse>> payoffFloorPlan(
            @Valid @RequestBody FloorPlanPayoffRequest request) {
        log.info("Processing floor plan payoff - VIN: {}", request.getVin());
        FloorPlanPayoffResponse response = floorPlanService.payoffFloorPlan(request);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- Calculate Interest ---------------------------------------------------

    @PostMapping("/interest")
    public ResponseEntity<ApiResponse<FloorPlanInterestResponse>> calculateInterest(
            @Valid @RequestBody FloorPlanInterestRequest request) {
        log.info("Calculating floor plan interest - dealer: {}, mode: {}",
                request.getDealerCode(), request.getMode());
        FloorPlanInterestResponse response = floorPlanService.calculateInterest(request);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- List Lenders ---------------------------------------------------------

    @GetMapping("/lenders")
    public ResponseEntity<ApiResponse<List<FloorPlanLenderResponse>>> listLenders() {
        log.info("Listing floor plan lenders");
        List<FloorPlanLenderResponse> response = floorPlanService.listLenders();
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- Exposure Report ------------------------------------------------------

    @GetMapping("/reports/exposure")
    public ResponseEntity<ApiResponse<FloorPlanExposureResponse>> generateExposureReport(
            @RequestParam String dealerCode) {
        log.info("Generating floor plan exposure report - dealer: {}", dealerCode);
        FloorPlanExposureResponse response = floorPlanReportService.generateExposureReport(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(response));
    }
}
