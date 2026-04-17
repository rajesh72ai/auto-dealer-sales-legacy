package com.autosales.modules.registration.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.RegistrationRequest;
import com.autosales.modules.registration.dto.RegistrationResponse;
import com.autosales.modules.registration.dto.RegistrationStatusUpdateRequest;
import com.autosales.modules.registration.service.RegistrationService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for vehicle registration management.
 * Port of REGGEN00, REGINQ00, REGVAL00, REGSUB00, REGSTS00.
 */
@RestController
@RequestMapping("/api/registrations")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','OPERATOR','AGENT_SERVICE')")
@Slf4j
public class RegistrationController {

    private final RegistrationService service;
    private final ResponseFormatter responseFormatter;

    public RegistrationController(RegistrationService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<RegistrationResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing registrations — status: {}, page: {}", status, page);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100), Sort.by("createdTs").descending());
        return ResponseEntity.ok(service.findAll(status, pageRequest));
    }

    @GetMapping("/{regId}")
    public ResponseEntity<ApiResponse<RegistrationResponse>> getById(@PathVariable String regId) {
        log.info("Getting registration: {}", regId);
        return ResponseEntity.ok(responseFormatter.success(service.findById(regId)));
    }

    @GetMapping("/by-vin/{vin}")
    public ResponseEntity<ApiResponse<List<RegistrationResponse>>> getByVin(@PathVariable String vin) {
        log.info("Getting registrations by VIN: {}", vin);
        return ResponseEntity.ok(responseFormatter.success(service.findByVin(vin)));
    }

    @GetMapping("/by-deal/{dealNumber}")
    public ResponseEntity<ApiResponse<RegistrationResponse>> getByDealNumber(@PathVariable String dealNumber) {
        log.info("Getting registration by deal: {}", dealNumber);
        return ResponseEntity.ok(responseFormatter.success(service.findByDealNumber(dealNumber)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RegistrationResponse>> create(@Valid @RequestBody RegistrationRequest request) {
        log.info("Creating registration for deal: {}", request.getDealNumber());
        RegistrationResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Registration created successfully"));
    }

    @PostMapping("/{regId}/validate")
    public ResponseEntity<ApiResponse<RegistrationResponse>> validate(@PathVariable String regId) {
        log.info("Validating registration: {}", regId);
        return ResponseEntity.ok(responseFormatter.success(service.validate(regId), "Registration validated successfully"));
    }

    @PostMapping("/{regId}/submit")
    public ResponseEntity<ApiResponse<RegistrationResponse>> submit(@PathVariable String regId) {
        log.info("Submitting registration: {}", regId);
        return ResponseEntity.ok(responseFormatter.success(service.submit(regId), "Registration submitted to state DMV"));
    }

    @PatchMapping("/{regId}/status")
    public ResponseEntity<ApiResponse<RegistrationResponse>> updateStatus(
            @PathVariable String regId,
            @Valid @RequestBody RegistrationStatusUpdateRequest request) {
        log.info("Updating registration status: {} → {}", regId, request.getNewStatus());
        return ResponseEntity.ok(responseFormatter.success(
                service.updateStatus(regId, request), "Registration status updated successfully"));
    }
}
