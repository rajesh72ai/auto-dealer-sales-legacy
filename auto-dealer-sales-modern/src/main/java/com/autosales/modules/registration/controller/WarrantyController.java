package com.autosales.modules.registration.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.WarrantyResponse;
import com.autosales.modules.registration.service.WarrantyService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * REST controller for warranty coverage management.
 * Port of WRCWAR00 (warranty registration) and WRCINQ00 (warranty inquiry).
 */
@RestController
@RequestMapping("/api/warranties")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','SALESPERSON','OPERATOR')")
@Slf4j
public class WarrantyController {

    private final WarrantyService service;
    private final ResponseFormatter responseFormatter;

    public WarrantyController(WarrantyService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping("/by-vin/{vin}")
    public ResponseEntity<ApiResponse<List<WarrantyResponse>>> getByVin(@PathVariable String vin) {
        log.info("Getting warranties for VIN: {}", vin);
        return ResponseEntity.ok(responseFormatter.success(service.findByVin(vin)));
    }

    @GetMapping("/by-deal/{dealNumber}")
    public ResponseEntity<ApiResponse<List<WarrantyResponse>>> getByDealNumber(@PathVariable String dealNumber) {
        log.info("Getting warranties for deal: {}", dealNumber);
        return ResponseEntity.ok(responseFormatter.success(service.findByDealNumber(dealNumber)));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<List<WarrantyResponse>>> register(
            @RequestParam String vin,
            @RequestParam String dealNumber,
            @RequestParam LocalDate saleDate) {
        log.info("Registering warranties for VIN: {} deal: {}", vin, dealNumber);
        List<WarrantyResponse> response = service.registerWarranties(vin, dealNumber, saleDate);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Warranties registered successfully"));
    }
}
