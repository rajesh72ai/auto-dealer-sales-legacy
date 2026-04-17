package com.autosales.modules.customer.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.customer.dto.CreditCheckRequest;
import com.autosales.modules.customer.dto.CreditCheckResponse;
import com.autosales.modules.customer.service.CreditCheckService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for credit check operations.
 * Port of CRDCHK00.cbl — credit pre-qualification and scoring.
 */
@RestController
@RequestMapping("/api/credit-checks")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR','AGENT_SERVICE')")
@Slf4j
public class CreditCheckController {

    private final CreditCheckService service;
    private final ResponseFormatter responseFormatter;

    public CreditCheckController(CreditCheckService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CreditCheckResponse>> checkCredit(@Valid @RequestBody CreditCheckRequest request) {
        log.info("Running credit check for customer: {}, bureau: {}", request.getCustomerId(), request.getBureauCode());
        CreditCheckResponse response = service.checkCredit(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseFormatter.success(response, "Credit check completed"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CreditCheckResponse>> getById(@PathVariable Integer id) {
        log.info("Getting credit check by id: {}", id);
        CreditCheckResponse response = service.findById(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<ApiResponse<List<CreditCheckResponse>>> getByCustomerId(@PathVariable Integer customerId) {
        log.info("Getting credit checks for customer: {}", customerId);
        List<CreditCheckResponse> responses = service.findByCustomerId(customerId);
        return ResponseEntity.ok(responseFormatter.success(responses));
    }
}
