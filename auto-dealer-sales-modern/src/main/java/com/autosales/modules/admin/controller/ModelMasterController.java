package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.ModelMasterRequest;
import com.autosales.modules.admin.dto.ModelMasterResponse;
import com.autosales.modules.admin.service.ModelMasterService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for vehicle model master administration.
 * Port of MDLADM00.cbl — model master file maintenance (add/update/list).
 */
@RestController
@RequestMapping("/api/admin/models")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class ModelMasterController {

    private final ModelMasterService service;
    private final ResponseFormatter responseFormatter;

    public ModelMasterController(ModelMasterService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<ModelMasterResponse>> list(
            @RequestParam(required = false) Short year,
            @RequestParam(required = false) String make,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing models - year: {}, make: {}, page: {}, size: {}", year, make, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<ModelMasterResponse> result = service.findAll(year, make, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{year}/{make}/{model}")
    public ResponseEntity<ApiResponse<ModelMasterResponse>> getByKey(
            @PathVariable Short year,
            @PathVariable String make,
            @PathVariable String model) {
        log.info("Getting model by key - year: {}, make: {}, model: {}", year, make, model);
        ModelMasterResponse response = service.findByKey(year, make, model);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ModelMasterResponse>> create(@Valid @RequestBody ModelMasterRequest request) {
        log.info("Creating model: {} {} {}", request.getModelYear(), request.getMakeCode(), request.getModelCode());
        ModelMasterResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Model created successfully"));
    }

    @PutMapping("/{year}/{make}/{model}")
    public ResponseEntity<ApiResponse<ModelMasterResponse>> update(
            @PathVariable Short year,
            @PathVariable String make,
            @PathVariable String model,
            @Valid @RequestBody ModelMasterRequest request) {
        log.info("Updating model: {} {} {}", year, make, model);
        ModelMasterResponse response = service.update(year, make, model, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Model updated successfully"));
    }
}
