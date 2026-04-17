package com.autosales.modules.registration.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.registration.dto.*;
import com.autosales.modules.registration.service.RecallService;
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
 * REST controller for recall campaign management.
 * Port of WRCRCL00 (recall management), WRCRCLB0 (batch feed), WRCNOTF0 (notifications).
 */
@RestController
@RequestMapping("/api/recalls")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
public class RecallController {

    private final RecallService service;
    private final ResponseFormatter responseFormatter;

    public RecallController(RecallService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    // ─── Campaigns ──────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<PaginatedResponse<RecallCampaignResponse>> listCampaigns(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing recall campaigns — status: {}", status);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100), Sort.by("announcedDate").descending());
        return ResponseEntity.ok(service.findAllCampaigns(status, pageRequest));
    }

    @GetMapping("/{recallId}")
    public ResponseEntity<ApiResponse<RecallCampaignResponse>> getCampaign(@PathVariable String recallId) {
        log.info("Getting recall campaign: {}", recallId);
        return ResponseEntity.ok(responseFormatter.success(service.findCampaignById(recallId)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RecallCampaignResponse>> createCampaign(
            @Valid @RequestBody RecallCampaignRequest request) {
        log.info("Creating recall campaign: {}", request.getRecallId());
        RecallCampaignResponse response = service.createCampaign(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Recall campaign created successfully"));
    }

    // ─── Vehicles ───────────────────────────────────────────────────────

    @GetMapping("/{recallId}/vehicles")
    public ResponseEntity<PaginatedResponse<RecallVehicleResponse>> listVehicles(
            @PathVariable String recallId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing vehicles for recall: {} status: {}", recallId, status);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        return ResponseEntity.ok(service.findVehiclesByRecall(recallId, status, pageRequest));
    }

    @PostMapping("/{recallId}/vehicles")
    public ResponseEntity<ApiResponse<RecallVehicleResponse>> addVehicle(
            @PathVariable String recallId,
            @RequestParam String vin,
            @RequestParam(required = false) String dealerCode) {
        log.info("Adding VIN {} to recall {}", vin, recallId);
        RecallVehicleResponse response = service.addVehicle(recallId, vin, dealerCode);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Vehicle added to recall campaign"));
    }

    @PatchMapping("/{recallId}/vehicles/{vin}/status")
    public ResponseEntity<ApiResponse<RecallVehicleResponse>> updateVehicleStatus(
            @PathVariable String recallId,
            @PathVariable String vin,
            @Valid @RequestBody RecallVehicleStatusRequest request) {
        log.info("Updating recall vehicle status: {}/{} → {}", recallId, vin, request.getNewStatus());
        return ResponseEntity.ok(responseFormatter.success(
                service.updateVehicleStatus(recallId, vin, request), "Vehicle recall status updated"));
    }

    @GetMapping("/by-vin/{vin}")
    public ResponseEntity<ApiResponse<List<RecallVehicleResponse>>> getRecallsByVin(@PathVariable String vin) {
        log.info("Getting recalls for VIN: {}", vin);
        return ResponseEntity.ok(responseFormatter.success(service.findRecallsByVin(vin)));
    }

    // ─── Notifications ──────────────────────────────────────────────────

    @GetMapping("/{recallId}/notifications")
    public ResponseEntity<ApiResponse<List<RecallNotificationResponse>>> listNotifications(
            @PathVariable String recallId) {
        log.info("Listing notifications for recall: {}", recallId);
        return ResponseEntity.ok(responseFormatter.success(service.findNotificationsByRecall(recallId)));
    }

    @PostMapping("/{recallId}/notifications")
    public ResponseEntity<ApiResponse<RecallNotificationResponse>> createNotification(
            @PathVariable String recallId,
            @RequestParam String vin,
            @RequestParam(required = false) Integer customerId,
            @RequestParam(required = false, defaultValue = "M") String notifType) {
        log.info("Creating notification for recall: {} vin: {}", recallId, vin);
        RecallNotificationResponse response = service.createNotification(recallId, vin, customerId, notifType);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Recall notification created"));
    }
}
