package com.autosales.modules.batch.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.batch.dto.*;
import com.autosales.modules.batch.service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for batch job management and execution.
 * Port of BATRSTRT.cbl (checkpoint management) and batch job control.
 * Provides endpoints to list jobs, view status, manage checkpoints,
 * and trigger batch runs on demand.
 */
@RestController
@RequestMapping("/api/batch/jobs")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class BatchJobController {

    private final CheckpointService checkpointService;
    private final DailyBatchService dailyBatchService;
    private final MonthlyBatchService monthlyBatchService;
    private final WeeklyBatchService weeklyBatchService;
    private final PurgeBatchService purgeBatchService;
    private final ValidationBatchService validationBatchService;
    private final GlPostingService glPostingService;
    private final InboundBatchService inboundBatchService;
    private final IntegrationBatchService integrationBatchService;
    private final ResponseFormatter responseFormatter;

    // ── Batch Job Listing ─────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<ApiResponse<List<BatchJobResponse>>> listBatchJobs() {
        log.info("GET /api/batch/jobs");
        List<BatchJobResponse> jobs = checkpointService.getAllBatchJobs();
        return ResponseEntity.ok(responseFormatter.success(jobs));
    }

    @GetMapping("/{programId}")
    public ResponseEntity<ApiResponse<BatchJobResponse>> getBatchJob(@PathVariable String programId) {
        log.info("GET /api/batch/jobs/{}", programId);
        BatchJobResponse job = checkpointService.getBatchJob(programId);
        return ResponseEntity.ok(responseFormatter.success(job));
    }

    // ── Checkpoint Management (BATRSTRT) ──────────────────────────────

    @GetMapping("/{programId}/checkpoints")
    public ResponseEntity<ApiResponse<List<CheckpointResponse>>> getCheckpoints(
            @PathVariable String programId) {
        log.info("GET /api/batch/jobs/{}/checkpoints", programId);
        List<CheckpointResponse> checkpoints = checkpointService.getCheckpoints(programId);
        return ResponseEntity.ok(responseFormatter.success(checkpoints));
    }

    @PostMapping("/checkpoints/action")
    public ResponseEntity<ApiResponse<CheckpointResponse>> checkpointAction(
            @Valid @RequestBody CheckpointActionRequest request) {
        log.info("POST /api/batch/jobs/checkpoints/action — {} for {}",
                request.getAction(), request.getProgramId());
        CheckpointResponse result = checkpointService.executeCheckpointAction(request);
        return ResponseEntity.ok(responseFormatter.success(result,
                request.getAction() + " completed for " + request.getProgramId()));
    }

    // ── Batch Job Execution ───────────────────────────────────────────

    @PostMapping("/run/daily")
    public ResponseEntity<ApiResponse<BatchRunResult>> runDaily() {
        log.info("POST /api/batch/jobs/run/daily");
        BatchRunResult result = dailyBatchService.runDailyEndOfDay();
        return ResponseEntity.ok(responseFormatter.success(result, "Daily batch completed"));
    }

    @PostMapping("/run/monthly")
    public ResponseEntity<ApiResponse<BatchRunResult>> runMonthly() {
        log.info("POST /api/batch/jobs/run/monthly");
        BatchRunResult result = monthlyBatchService.runMonthlyClose();
        return ResponseEntity.ok(responseFormatter.success(result, "Monthly close completed"));
    }

    @PostMapping("/run/weekly")
    public ResponseEntity<ApiResponse<BatchRunResult>> runWeekly() {
        log.info("POST /api/batch/jobs/run/weekly");
        BatchRunResult result = weeklyBatchService.runWeeklyProcessing();
        return ResponseEntity.ok(responseFormatter.success(result, "Weekly batch completed"));
    }

    @PostMapping("/run/purge")
    public ResponseEntity<ApiResponse<BatchRunResult>> runPurge() {
        log.info("POST /api/batch/jobs/run/purge");
        BatchRunResult result = purgeBatchService.runPurge();
        return ResponseEntity.ok(responseFormatter.success(result, "Purge batch completed"));
    }

    @PostMapping("/run/validation")
    public ResponseEntity<ApiResponse<BatchRunResult>> runValidation() {
        log.info("POST /api/batch/jobs/run/validation");
        BatchRunResult result = validationBatchService.runValidation();
        return ResponseEntity.ok(responseFormatter.success(result, "Validation batch completed"));
    }

    @PostMapping("/run/gl-posting")
    public ResponseEntity<ApiResponse<BatchRunResult>> runGlPosting() {
        log.info("POST /api/batch/jobs/run/gl-posting");
        BatchRunResult result = glPostingService.runGlPosting();
        return ResponseEntity.ok(responseFormatter.success(result, "GL posting completed"));
    }

    @PostMapping("/run/crm-extract")
    public ResponseEntity<ApiResponse<CrmExtractResponse>> runCrmExtract() {
        log.info("POST /api/batch/jobs/run/crm-extract");
        CrmExtractResponse result = integrationBatchService.runCrmExtract();
        return ResponseEntity.ok(responseFormatter.success(result, "CRM extract completed"));
    }

    @PostMapping("/run/dms-extract")
    public ResponseEntity<ApiResponse<DmsExtractResponse>> runDmsExtract() {
        log.info("POST /api/batch/jobs/run/dms-extract");
        DmsExtractResponse result = integrationBatchService.runDmsExtract();
        return ResponseEntity.ok(responseFormatter.success(result, "DMS extract completed"));
    }

    @PostMapping("/run/datalake-extract")
    public ResponseEntity<ApiResponse<DataLakeExtractResponse>> runDataLakeExtract() {
        log.info("POST /api/batch/jobs/run/datalake-extract");
        DataLakeExtractResponse result = integrationBatchService.runDataLakeExtract();
        return ResponseEntity.ok(responseFormatter.success(result, "Data lake extract completed"));
    }

    @PostMapping("/run/inbound")
    public ResponseEntity<ApiResponse<InboundProcessingResponse>> runInbound(
            @Valid @RequestBody List<InboundVehicleRequest> records) {
        log.info("POST /api/batch/jobs/run/inbound — {} records", records.size());
        InboundProcessingResponse result = inboundBatchService.processInboundFeed(records);
        return ResponseEntity.ok(responseFormatter.success(result, "Inbound processing completed"));
    }
}
