package com.autosales.modules.vehicle.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.vehicle.dto.SnapshotCaptureRequest;
import com.autosales.modules.vehicle.dto.SnapshotResponse;
import com.autosales.modules.vehicle.service.StockSnapshotService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * REST controller for stock snapshot capture and historical queries.
 * Port of STKSNAP0.cbl — daily stock position snapshot and reporting.
 */
@RestController
@RequestMapping("/api/stock/snapshots")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class StockSnapshotController {

    private final StockSnapshotService service;
    private final ResponseFormatter responseFormatter;

    @PostMapping("/capture")
    public ResponseEntity<ApiResponse<Integer>> captureSnapshot(
            @Valid @RequestBody SnapshotCaptureRequest request) {
        log.info("POST /api/stock/snapshots/capture — dealer={}, date={}",
                request.getDealerCode(), request.getSnapshotDate());
        int count = service.captureSnapshot(request);
        return ResponseEntity.ok(responseFormatter.success(count,
                "Snapshot captured successfully: " + count + " records created"));
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<SnapshotResponse>> getSnapshots(
            @RequestParam String dealerCode,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/stock/snapshots — dealer={}, from={}, to={}, page={}, size={}",
                dealerCode, from, to, page, size);
        PaginatedResponse<SnapshotResponse> response = service.getSnapshots(dealerCode, from, to, page, size);
        return ResponseEntity.ok(response);
    }
}
