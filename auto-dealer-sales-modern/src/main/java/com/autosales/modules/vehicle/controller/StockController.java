package com.autosales.modules.vehicle.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.StockUpdateResult;
import com.autosales.modules.vehicle.dto.*;
import com.autosales.modules.vehicle.service.StockManagementService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for stock management operations.
 * Port of 8 legacy programs: STKINQ00, STKSUM00, STKADJT0, STKAGIN0, STKALRT0, STKHLD00, STKRCN00, STKVALS0.
 *
 * <p>Provides endpoints for stock position inquiry, summary, adjustments,
 * aging analysis, low-stock alerts, vehicle hold/release, reconciliation,
 * and inventory valuation.</p>
 */
@RestController
@RequestMapping("/api/stock")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class StockController {

    private final StockManagementService stockManagementService;
    private final ResponseFormatter responseFormatter;

    /**
     * GET /api/stock/positions — Stock position inquiry by dealer.
     * Port of STKINQ00.
     */
    @GetMapping("/positions")
    public ResponseEntity<ApiResponse<List<StockPositionResponse>>> getPositions(
            @RequestParam String dealerCode) {
        log.info("GET /api/stock/positions?dealerCode={}", dealerCode);
        List<StockPositionResponse> positions = stockManagementService.getPositions(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(positions));
    }

    /**
     * GET /api/stock/summary — Stock summary with totals and value.
     * Port of STKSUM00.
     */
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<StockSummaryResponse>> getSummary(
            @RequestParam String dealerCode) {
        log.info("GET /api/stock/summary?dealerCode={}", dealerCode);
        StockSummaryResponse summary = stockManagementService.getSummary(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(summary));
    }

    /**
     * POST /api/stock/adjustments — Create a stock adjustment.
     * Port of STKADJT0.
     */
    @PostMapping("/adjustments")
    public ResponseEntity<ApiResponse<StockAdjustmentResponse>> createAdjustment(
            @RequestBody StockAdjustmentRequest request) {
        log.info("POST /api/stock/adjustments type={} vin={}", request.getAdjustType(), request.getVin());
        StockAdjustmentResponse response = stockManagementService.createAdjustment(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Stock adjustment created successfully"));
    }

    /**
     * GET /api/stock/adjustments — List stock adjustments with pagination.
     * Port of STKADJT0 inquiry mode.
     */
    @GetMapping("/adjustments")
    public ResponseEntity<PaginatedResponse<StockAdjustmentResponse>> listAdjustments(
            @RequestParam String dealerCode,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/stock/adjustments?dealerCode={}&page={}&size={}", dealerCode, page, size);
        PaginatedResponse<StockAdjustmentResponse> result =
                stockManagementService.listAdjustments(dealerCode, page, size);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/stock/aging — Aging analysis with curtailment warnings.
     * Port of STKAGIN0.
     */
    @GetMapping("/aging")
    public ResponseEntity<ApiResponse<AgingReportResponse>> getAgingAnalysis(
            @RequestParam String dealerCode) {
        log.info("GET /api/stock/aging?dealerCode={}", dealerCode);
        AgingReportResponse report = stockManagementService.getAgingAnalysis(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(report));
    }

    /**
     * GET /api/stock/alerts — Low-stock alerts with suggested order quantities.
     * Port of STKALRT0.
     */
    @GetMapping("/alerts")
    public ResponseEntity<ApiResponse<List<StockAlertResponse>>> getAlerts(
            @RequestParam String dealerCode) {
        log.info("GET /api/stock/alerts?dealerCode={}", dealerCode);
        List<StockAlertResponse> alerts = stockManagementService.getAlerts(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(alerts));
    }

    /**
     * POST /api/stock/{vin}/hold — Place a vehicle on hold.
     * Port of STKHLD00 HOLD function.
     */
    @PostMapping("/{vin}/hold")
    public ResponseEntity<ApiResponse<StockUpdateResult>> holdVehicle(
            @PathVariable String vin,
            @RequestBody StockHoldRequest request) {
        log.info("POST /api/stock/{}/hold holdBy={}", vin, request.getHoldBy());
        StockUpdateResult result = stockManagementService.holdVehicle(vin, request);
        return ResponseEntity.ok(responseFormatter.success(result, "Vehicle placed on hold"));
    }

    /**
     * POST /api/stock/{vin}/release — Release a vehicle from hold.
     * Port of STKHLD00 RLSE function.
     */
    @PostMapping("/{vin}/release")
    public ResponseEntity<ApiResponse<StockUpdateResult>> releaseVehicle(
            @PathVariable String vin,
            @RequestBody StockReleaseRequest request) {
        log.info("POST /api/stock/{}/release releaseBy={}", vin, request.getReleaseBy());
        StockUpdateResult result = stockManagementService.releaseVehicle(vin, request);
        return ResponseEntity.ok(responseFormatter.success(result, "Vehicle released from hold"));
    }

    /**
     * POST /api/stock/reconcile — Run stock reconciliation.
     * Port of STKRCN00.
     */
    @PostMapping("/reconcile")
    public ResponseEntity<ApiResponse<ReconciliationResponse>> reconcile(
            @RequestParam String dealerCode) {
        log.info("POST /api/stock/reconcile?dealerCode={}", dealerCode);
        ReconciliationResponse response = stockManagementService.reconcile(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(response, "Stock reconciliation complete"));
    }

    /**
     * GET /api/stock/valuation — Stock valuation by category.
     * Port of STKVALS0.
     */
    @GetMapping("/valuation")
    public ResponseEntity<ApiResponse<StockValuationResponse>> getValuation(
            @RequestParam String dealerCode) {
        log.info("GET /api/stock/valuation?dealerCode={}", dealerCode);
        StockValuationResponse valuation = stockManagementService.getValuation(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(valuation));
    }
}
