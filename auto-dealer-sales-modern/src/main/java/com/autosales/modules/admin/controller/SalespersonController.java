package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.SalespersonRequest;
import com.autosales.modules.admin.dto.SalespersonResponse;
import com.autosales.modules.admin.service.SalespersonService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for salesperson administration.
 * Port of SLPADM00.cbl — salesperson master file maintenance (add/update/list by dealer).
 */
@RestController
@RequestMapping("/api/admin/salespersons")
@PreAuthorize("hasRole('ADMIN')")
@Slf4j
public class SalespersonController {

    private final SalespersonService service;
    private final ResponseFormatter responseFormatter;

    public SalespersonController(SalespersonService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<SalespersonResponse>> list(
            @RequestParam String dealerCode,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing salespersons - dealerCode: {}, page: {}, size: {}", dealerCode, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<SalespersonResponse> result = service.findAll(dealerCode, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SalespersonResponse>> getById(@PathVariable String id) {
        log.info("Getting salesperson by id: {}", id);
        SalespersonResponse response = service.findById(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SalespersonResponse>> create(@Valid @RequestBody SalespersonRequest request) {
        log.info("Creating salesperson: {} for dealer: {}", request.getSalespersonName(), request.getDealerCode());
        SalespersonResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Salesperson created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<SalespersonResponse>> update(
            @PathVariable String id,
            @Valid @RequestBody SalespersonRequest request) {
        log.info("Updating salesperson: {}", id);
        SalespersonResponse response = service.update(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Salesperson updated successfully"));
    }
}
