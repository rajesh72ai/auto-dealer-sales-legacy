package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.IncentiveProgramRequest;
import com.autosales.modules.admin.dto.IncentiveProgramResponse;
import com.autosales.modules.admin.service.IncentiveProgramService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for incentive program administration.
 * Port of INCADM00.cbl — incentive program master file maintenance (add/update/activate/deactivate).
 */
@RestController
@RequestMapping("/api/admin/incentives")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class IncentiveProgramController {

    private final IncentiveProgramService service;
    private final ResponseFormatter responseFormatter;

    public IncentiveProgramController(IncentiveProgramService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<IncentiveProgramResponse>> list(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String active,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing incentive programs - type: {}, active: {}, page: {}, size: {}", type, active, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<IncentiveProgramResponse> result = service.findAll(type, active, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<IncentiveProgramResponse>> getById(@PathVariable String id) {
        log.info("Getting incentive program by id: {}", id);
        IncentiveProgramResponse response = service.findById(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<IncentiveProgramResponse>> create(@Valid @RequestBody IncentiveProgramRequest request) {
        log.info("Creating incentive program: {}", request.getIncentiveName());
        IncentiveProgramResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Incentive program created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<IncentiveProgramResponse>> update(
            @PathVariable String id,
            @Valid @RequestBody IncentiveProgramRequest request) {
        log.info("Updating incentive program: {}", id);
        IncentiveProgramResponse response = service.update(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Incentive program updated successfully"));
    }

    @PatchMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<IncentiveProgramResponse>> activate(@PathVariable String id) {
        log.info("Activating incentive program: {}", id);
        IncentiveProgramResponse response = service.activate(id);
        return ResponseEntity.ok(responseFormatter.success(response, "Incentive program activated successfully"));
    }

    @PatchMapping("/{id}/deactivate")
    public ResponseEntity<ApiResponse<IncentiveProgramResponse>> deactivate(@PathVariable String id) {
        log.info("Deactivating incentive program: {}", id);
        IncentiveProgramResponse response = service.deactivate(id);
        return ResponseEntity.ok(responseFormatter.success(response, "Incentive program deactivated successfully"));
    }
}
