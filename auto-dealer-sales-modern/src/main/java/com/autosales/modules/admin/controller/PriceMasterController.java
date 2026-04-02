package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.PriceMasterRequest;
import com.autosales.modules.admin.dto.PriceMasterResponse;
import com.autosales.modules.admin.service.PriceMasterService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * REST controller for vehicle pricing administration.
 * Port of PRCADM00.cbl — price master file maintenance (add/update/list/history).
 */
@RestController
@RequestMapping("/api/admin/pricing")
@PreAuthorize("hasRole('ADMIN')")
@Slf4j
public class PriceMasterController {

    private final PriceMasterService service;
    private final ResponseFormatter responseFormatter;

    public PriceMasterController(PriceMasterService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<PriceMasterResponse>> list(
            @RequestParam(required = false) Short year,
            @RequestParam(required = false) String make,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing pricing - year: {}, make: {}, page: {}, size: {}", year, make, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<PriceMasterResponse> result = service.findAll(year, make, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{year}/{make}/{model}")
    public ResponseEntity<ApiResponse<PriceMasterResponse>> getCurrentEffective(
            @PathVariable Short year,
            @PathVariable String make,
            @PathVariable String model) {
        log.info("Getting current effective price - year: {}, make: {}, model: {}", year, make, model);
        PriceMasterResponse response = service.findCurrentEffective(year, make, model);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @GetMapping("/{year}/{make}/{model}/history")
    public ResponseEntity<ApiResponse<List<PriceMasterResponse>>> getHistory(
            @PathVariable Short year,
            @PathVariable String make,
            @PathVariable String model) {
        log.info("Getting price history - year: {}, make: {}, model: {}", year, make, model);
        List<PriceMasterResponse> history = service.findHistory(year, make, model);
        return ResponseEntity.ok(responseFormatter.success(history));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PriceMasterResponse>> create(@Valid @RequestBody PriceMasterRequest request) {
        log.info("Creating price entry: {} {} {}", request.getModelYear(), request.getMakeCode(), request.getModelCode());
        PriceMasterResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Price entry created successfully"));
    }

    @PutMapping("/{year}/{make}/{model}/{date}")
    public ResponseEntity<ApiResponse<PriceMasterResponse>> update(
            @PathVariable Short year,
            @PathVariable String make,
            @PathVariable String model,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @Valid @RequestBody PriceMasterRequest request) {
        log.info("Updating price entry: {} {} {} effective {}", year, make, model, date);
        PriceMasterResponse response = service.update(year, make, model, date, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Price entry updated successfully"));
    }
}
