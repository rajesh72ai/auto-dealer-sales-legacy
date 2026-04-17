package com.autosales.modules.registration.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.WarrantyClaimRequest;
import com.autosales.modules.registration.dto.WarrantyClaimResponse;
import com.autosales.modules.registration.dto.WarrantyClaimSummaryResponse;
import com.autosales.modules.registration.service.WarrantyClaimService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * REST controller for warranty claims and reporting.
 * Port of WRCRPT00 (claims summary report).
 */
@RestController
@RequestMapping("/api/warranty-claims")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','OPERATOR')")
@Slf4j
public class WarrantyClaimController {

    private final WarrantyClaimService service;
    private final ResponseFormatter responseFormatter;

    public WarrantyClaimController(WarrantyClaimService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<WarrantyClaimResponse>> list(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing warranty claims — dealer: {}, status: {}", dealerCode, status);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100), Sort.by("claimDate").descending());
        return ResponseEntity.ok(service.findByDealer(dealerCode, status, pageRequest));
    }

    @GetMapping("/{claimNumber}")
    public ResponseEntity<ApiResponse<WarrantyClaimResponse>> getByClaimNumber(@PathVariable String claimNumber) {
        log.info("Getting warranty claim: {}", claimNumber);
        return ResponseEntity.ok(responseFormatter.success(service.findByClaimNumber(claimNumber)));
    }

    @GetMapping("/by-vin/{vin}")
    public ResponseEntity<ApiResponse<List<WarrantyClaimResponse>>> getByVin(@PathVariable String vin) {
        log.info("Getting warranty claims for VIN: {}", vin);
        return ResponseEntity.ok(responseFormatter.success(service.findByVin(vin)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<WarrantyClaimResponse>> create(@Valid @RequestBody WarrantyClaimRequest request) {
        log.info("Creating warranty claim for VIN: {}", request.getVin());
        WarrantyClaimResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Warranty claim created successfully"));
    }

    @PutMapping("/{claimNumber}")
    public ResponseEntity<ApiResponse<WarrantyClaimResponse>> update(
            @PathVariable String claimNumber,
            @Valid @RequestBody WarrantyClaimRequest request) {
        log.info("Updating warranty claim: {}", claimNumber);
        return ResponseEntity.ok(responseFormatter.success(
                service.update(claimNumber, request), "Warranty claim updated successfully"));
    }

    @GetMapping("/report")
    public ResponseEntity<ApiResponse<WarrantyClaimSummaryResponse>> report(
            @RequestParam String dealerCode,
            @RequestParam(required = false) LocalDate fromDate,
            @RequestParam(required = false) LocalDate toDate) {
        log.info("Generating claims report — dealer: {} from: {} to: {}", dealerCode, fromDate, toDate);
        return ResponseEntity.ok(responseFormatter.success(service.generateReport(dealerCode, fromDate, toDate)));
    }
}
