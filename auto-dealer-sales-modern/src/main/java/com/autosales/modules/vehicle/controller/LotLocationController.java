package com.autosales.modules.vehicle.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.vehicle.dto.LotLocationRequest;
import com.autosales.modules.vehicle.dto.LotLocationResponse;
import com.autosales.modules.vehicle.service.LotLocationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for lot location management.
 * Port of VEHLOC00.cbl — vehicle lot location maintenance (add/update/list/assign).
 */
@RestController
@RequestMapping("/api/lot-locations")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class LotLocationController {

    private final LotLocationService service;
    private final ResponseFormatter responseFormatter;

    @GetMapping
    public ResponseEntity<ApiResponse<List<LotLocationResponse>>> list(
            @RequestParam String dealerCode) {
        log.info("Listing lot locations for dealerCode={}", dealerCode);
        List<LotLocationResponse> locations = service.listLocations(dealerCode);
        return ResponseEntity.ok(responseFormatter.success(locations));
    }

    @GetMapping("/{dealerCode}/{locationCode}")
    public ResponseEntity<ApiResponse<LotLocationResponse>> get(
            @PathVariable String dealerCode,
            @PathVariable String locationCode) {
        log.info("Getting lot location dealerCode={}, locationCode={}", dealerCode, locationCode);
        LotLocationResponse location = service.getLocation(dealerCode, locationCode);
        return ResponseEntity.ok(responseFormatter.success(location));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<LotLocationResponse>> create(
            @Valid @RequestBody LotLocationRequest request) {
        log.info("Creating lot location dealerCode={}, locationCode={}", request.getDealerCode(), request.getLocationCode());
        LotLocationResponse created = service.createLocation(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(created, "Lot location created successfully"));
    }

    @PutMapping("/{dealerCode}/{locationCode}")
    public ResponseEntity<ApiResponse<LotLocationResponse>> update(
            @PathVariable String dealerCode,
            @PathVariable String locationCode,
            @Valid @RequestBody LotLocationRequest request) {
        log.info("Updating lot location dealerCode={}, locationCode={}", dealerCode, locationCode);
        LotLocationResponse updated = service.updateLocation(dealerCode, locationCode, request);
        return ResponseEntity.ok(responseFormatter.success(updated, "Lot location updated successfully"));
    }

    @DeleteMapping("/{dealerCode}/{locationCode}")
    public ResponseEntity<ApiResponse<LotLocationResponse>> deactivate(
            @PathVariable String dealerCode,
            @PathVariable String locationCode) {
        log.info("Deactivating lot location dealerCode={}, locationCode={}", dealerCode, locationCode);
        LotLocationResponse deactivated = service.deactivateLocation(dealerCode, locationCode);
        return ResponseEntity.ok(responseFormatter.success(deactivated, "Lot location deactivated successfully"));
    }

    @PostMapping("/{dealerCode}/{locationCode}/assign")
    public ResponseEntity<ApiResponse<Void>> assignVehicle(
            @PathVariable String dealerCode,
            @PathVariable String locationCode,
            @RequestParam String vin) {
        log.info("Assigning vehicle vin={} to lot location dealerCode={}, locationCode={}", vin, dealerCode, locationCode);
        service.assignVehicleToLocation(vin, dealerCode, locationCode);
        return ResponseEntity.ok(responseFormatter.success(null, "Vehicle assigned to location successfully"));
    }
}
