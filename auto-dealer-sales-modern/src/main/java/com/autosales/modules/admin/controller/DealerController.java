package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.DealerRequest;
import com.autosales.modules.admin.dto.DealerResponse;
import com.autosales.modules.admin.service.DealerService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for dealer administration.
 * Port of DLRADM00.cbl — dealer master file maintenance (add/update/list).
 */
@RestController
@RequestMapping("/api/admin/dealers")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class DealerController {

    private final DealerService service;
    private final ResponseFormatter responseFormatter;

    public DealerController(DealerService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<DealerResponse>> list(
            @RequestParam(required = false) String region,
            @RequestParam(required = false) String active,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing dealers - region: {}, active: {}, page: {}, size: {}", region, active, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<DealerResponse> result = service.findAll(region, active, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{code}")
    public ResponseEntity<ApiResponse<DealerResponse>> getByCode(@PathVariable String code) {
        log.info("Getting dealer by code: {}", code);
        DealerResponse response = service.findByCode(code);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<DealerResponse>> create(@Valid @RequestBody DealerRequest request) {
        log.info("Creating dealer: {}", request.getDealerCode());
        DealerResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Dealer created successfully"));
    }

    @PutMapping("/{code}")
    public ResponseEntity<ApiResponse<DealerResponse>> update(
            @PathVariable String code,
            @Valid @RequestBody DealerRequest request) {
        log.info("Updating dealer: {}", code);
        DealerResponse response = service.update(code, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Dealer updated successfully"));
    }
}
