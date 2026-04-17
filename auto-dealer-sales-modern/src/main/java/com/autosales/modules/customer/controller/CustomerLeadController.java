package com.autosales.modules.customer.controller;

import com.autosales.common.security.DealerScoped;
import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.customer.dto.LeadRequest;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.service.CustomerLeadService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for customer lead management.
 * Port of CUSTLD00.cbl — lead tracking and follow-up pipeline.
 */
@RestController
@RequestMapping("/api/leads")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','OPERATOR','AGENT_SERVICE')")
@Slf4j
public class CustomerLeadController {

    private final CustomerLeadService service;
    private final ResponseFormatter responseFormatter;

    public CustomerLeadController(CustomerLeadService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    @DealerScoped
    public ResponseEntity<PaginatedResponse<LeadResponse>> list(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String assignedSales,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing leads - dealer: {}, status: {}, sales: {}, page: {}, size: {}",
                dealerCode, status, assignedSales, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<LeadResponse> result = service.findAll(dealerCode, status, assignedSales, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LeadResponse>> getById(@PathVariable Integer id) {
        log.info("Getting lead by id: {}", id);
        LeadResponse response = service.findById(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<LeadResponse>> create(@Valid @RequestBody LeadRequest request) {
        log.info("Creating lead for customer: {} at dealer: {}", request.getCustomerId(), request.getDealerCode());
        LeadResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Lead created successfully"));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<LeadResponse>> updateStatus(
            @PathVariable Integer id,
            @RequestParam String status) {
        log.info("Updating lead {} status to: {}", id, status);
        LeadResponse response = service.updateStatus(id, status);
        return ResponseEntity.ok(responseFormatter.success(response, "Lead status updated"));
    }
}
