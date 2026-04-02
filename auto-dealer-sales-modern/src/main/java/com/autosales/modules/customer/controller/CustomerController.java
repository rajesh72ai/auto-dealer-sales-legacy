package com.autosales.modules.customer.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.customer.dto.CustomerHistoryResponse;
import com.autosales.modules.customer.dto.CustomerRequest;
import com.autosales.modules.customer.dto.CustomerResponse;
import com.autosales.modules.customer.service.CustomerService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for customer management.
 * Port of CUSTMN00.cbl — customer master file maintenance (add/update/search/list).
 */
@RestController
@RequestMapping("/api/customers")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK')")
@Slf4j
public class CustomerController {

    private final CustomerService service;
    private final ResponseFormatter responseFormatter;

    public CustomerController(CustomerService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<CustomerResponse>> list(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing customers - dealer: {}, sort: {}, page: {}, size: {}", dealerCode, sort, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<CustomerResponse> result = service.findAll(dealerCode, sort, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/search")
    public ResponseEntity<PaginatedResponse<CustomerResponse>> search(
            @RequestParam String type,
            @RequestParam String value,
            @RequestParam String dealerCode,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Searching customers - type: {}, value: {}, dealer: {}", type, value, dealerCode);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<CustomerResponse> result = service.search(type, value, dealerCode, pageRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> getById(@PathVariable Integer id) {
        log.info("Getting customer by id: {}", id);
        CustomerResponse response = service.findById(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @GetMapping("/{id}/history")
    public ResponseEntity<ApiResponse<CustomerHistoryResponse>> getHistory(@PathVariable Integer id) {
        log.info("Getting customer history for id: {}", id);
        CustomerHistoryResponse response = service.getHistory(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CustomerResponse>> create(@Valid @RequestBody CustomerRequest request) {
        log.info("Creating customer: {} {} for dealer: {}", request.getFirstName(), request.getLastName(), request.getDealerCode());
        CustomerResponse response = service.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Customer created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> update(
            @PathVariable Integer id,
            @Valid @RequestBody CustomerRequest request) {
        log.info("Updating customer: {}", id);
        CustomerResponse response = service.update(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Customer updated successfully"));
    }
}
