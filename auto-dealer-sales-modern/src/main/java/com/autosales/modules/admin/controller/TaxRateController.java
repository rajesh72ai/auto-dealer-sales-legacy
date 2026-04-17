package com.autosales.modules.admin.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.TaxCalculationResult;
import com.autosales.modules.admin.dto.TaxCalculationRequest;
import com.autosales.modules.admin.dto.TaxRateRequest;
import com.autosales.modules.admin.dto.TaxRateResponse;
import com.autosales.modules.admin.service.TaxRateService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * REST controller for tax rate administration.
 * Port of TAXADM00.cbl — tax rate master file maintenance and tax calculation.
 */
@RestController
@RequestMapping("/api/admin/tax-rates")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class TaxRateController {

    private final TaxRateService service;
    private final ResponseFormatter responseFormatter;

    public TaxRateController(TaxRateService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<TaxRateResponse>> list(
            @RequestParam(required = false) String state,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing tax rates - state: {}, page: {}, size: {}", state, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<TaxRateResponse> result = service.findAll(state, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{state}/{county}/{city}")
    public ResponseEntity<ApiResponse<TaxRateResponse>> getCurrentEffective(
            @PathVariable String state,
            @PathVariable String county,
            @PathVariable String city) {
        log.info("Getting current effective tax rate - state: {}, county: {}, city: {}", state, county, city);
        TaxRateResponse response = service.findCurrentEffective(state, county, city);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TaxRateResponse>> create(@Valid @RequestBody TaxRateRequest request) {
        log.info("Creating tax rate: {} {} {}", request.getStateCode(), request.getCountyCode(), request.getCityCode());
        TaxRateResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Tax rate created successfully"));
    }

    @PutMapping("/{state}/{county}/{city}/{date}")
    public ResponseEntity<ApiResponse<TaxRateResponse>> update(
            @PathVariable String state,
            @PathVariable String county,
            @PathVariable String city,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @Valid @RequestBody TaxRateRequest request) {
        log.info("Updating tax rate: {} {} {} effective {}", state, county, city, date);
        TaxRateResponse response = service.update(state, county, city, date, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Tax rate updated successfully"));
    }

    @PostMapping("/calculate")
    public ResponseEntity<ApiResponse<TaxCalculationResult>> calculateTax(@Valid @RequestBody TaxCalculationRequest request) {
        log.info("Calculating tax for state: {}, county: {}, city: {}", request.getStateCode(), request.getCountyCode(), request.getCityCode());
        TaxCalculationResult result = service.calculateTax(request);
        return ResponseEntity.ok(responseFormatter.success(result));
    }
}
