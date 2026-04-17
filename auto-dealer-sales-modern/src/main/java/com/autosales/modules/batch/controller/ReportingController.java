package com.autosales.modules.batch.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.batch.dto.*;
import com.autosales.modules.batch.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * REST controller for batch reporting and analytics.
 * Provides read-only endpoints for daily sales summaries, monthly snapshots,
 * commissions, validation reports, GL postings, and purge previews.
 */
@RestController
@RequestMapping("/api/batch/reports")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR','AGENT_SERVICE')")
@Slf4j
@RequiredArgsConstructor
public class ReportingController {

    private final DailyBatchService dailyBatchService;
    private final MonthlyBatchService monthlyBatchService;
    private final CommissionService commissionService;
    private final ValidationBatchService validationBatchService;
    private final GlPostingService glPostingService;
    private final PurgeBatchService purgeBatchService;
    private final ResponseFormatter responseFormatter;

    // ── Daily Sales Summaries ─────────────────────────────────────────

    @GetMapping("/daily-sales")
    public ResponseEntity<ApiResponse<List<DailySalesSummaryResponse>>> getDailySales(
            @RequestParam String dealerCode,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        log.info("GET /api/batch/reports/daily-sales — dealer: {}, {}-{}", dealerCode, startDate, endDate);
        List<DailySalesSummaryResponse> result = dailyBatchService.getDailySummaries(dealerCode, startDate, endDate);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    @GetMapping("/daily-sales/{date}")
    public ResponseEntity<ApiResponse<List<DailySalesSummaryResponse>>> getDailySalesByDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("GET /api/batch/reports/daily-sales/{}", date);
        List<DailySalesSummaryResponse> result = dailyBatchService.getSummariesByDate(date);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    // ── Monthly Snapshots ─────────────────────────────────────────────

    @GetMapping("/monthly-snapshots")
    public ResponseEntity<ApiResponse<List<MonthlySnapshotResponse>>> getMonthlySnapshots(
            @RequestParam String dealerCode) {
        log.info("GET /api/batch/reports/monthly-snapshots — dealer: {}", dealerCode);
        List<MonthlySnapshotResponse> result = monthlyBatchService.getSnapshotsByDealer(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    @GetMapping("/monthly-snapshots/{month}")
    public ResponseEntity<ApiResponse<List<MonthlySnapshotResponse>>> getSnapshotsByMonth(
            @PathVariable String month) {
        log.info("GET /api/batch/reports/monthly-snapshots/{}", month);
        List<MonthlySnapshotResponse> result = monthlyBatchService.getSnapshotsByMonth(month);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    // ── Commissions ───────────────────────────────────────────────────

    @GetMapping("/commissions")
    public ResponseEntity<ApiResponse<List<CommissionResponse>>> getCommissions(
            @RequestParam String dealerCode,
            @RequestParam String payPeriod) {
        log.info("GET /api/batch/reports/commissions — dealer: {}, period: {}", dealerCode, payPeriod);
        List<CommissionResponse> result = commissionService
                .getCommissionsByDealerAndPeriod(dealerCode, payPeriod);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    @GetMapping("/commissions/salesperson/{salespersonId}")
    public ResponseEntity<ApiResponse<List<CommissionResponse>>> getCommissionsBySalesperson(
            @PathVariable String salespersonId,
            @RequestParam String payPeriod) {
        log.info("GET /api/batch/reports/commissions/salesperson/{} — period: {}", salespersonId, payPeriod);
        List<CommissionResponse> result = commissionService
                .getCommissionsBySalesperson(salespersonId, payPeriod);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    @GetMapping("/commissions/unpaid")
    public ResponseEntity<ApiResponse<List<CommissionResponse>>> getUnpaidCommissions(
            @RequestParam String dealerCode) {
        log.info("GET /api/batch/reports/commissions/unpaid — dealer: {}", dealerCode);
        List<CommissionResponse> result = commissionService.getUnpaidCommissions(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    // ── Validation Report ─────────────────────────────────────────────

    @GetMapping("/validation")
    public ResponseEntity<ApiResponse<ValidationReportResponse>> getValidationReport() {
        log.info("GET /api/batch/reports/validation");
        ValidationReportResponse result = validationBatchService.generateValidationReport();
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    // ── GL Posting Preview ────────────────────────────────────────────

    @GetMapping("/gl-postings")
    public ResponseEntity<ApiResponse<GlPostingResponse>> getGlPostingPreview() {
        log.info("GET /api/batch/reports/gl-postings");
        GlPostingResponse result = glPostingService.previewGlPostings();
        return ResponseEntity.ok(responseFormatter.success(result));
    }

    // ── Purge Preview ─────────────────────────────────────────────────

    @GetMapping("/purge-preview")
    public ResponseEntity<ApiResponse<PurgeResultResponse>> getPurgePreview() {
        log.info("GET /api/batch/reports/purge-preview");
        PurgeResultResponse result = purgeBatchService.getPurgePreview();
        return ResponseEntity.ok(responseFormatter.success(result));
    }
}
