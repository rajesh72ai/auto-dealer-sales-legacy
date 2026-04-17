package com.autosales.modules.sales.controller;

import com.autosales.common.security.DealerScoped;
import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.sales.dto.*;
import com.autosales.modules.sales.service.DealService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for deal/sales management.
 * Port of SLSPR00.cbl  -- deal worksheet creation and negotiation
 *        SLSNG00.cbl  -- price negotiation & counter-offer
 *        SLSVL00.cbl  -- deal validation
 *        SLSAP00.cbl  -- manager approval workflow
 *        SLSTR00.cbl  -- trade-in evaluation
 *        SLSIN00.cbl  -- incentive application
 *        SLSCM00.cbl  -- deal completion / delivery
 *        SLSCN00.cbl  -- deal cancellation / unwind
 */
@RestController
@RequestMapping("/api/deals")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR','AGENT_SERVICE')")
@Slf4j
public class DealController {
    // NOTE: Write methods (create/negotiate/validate/approve/trade-in/incentives/
    // complete/cancel) deliberately carry method-level @PreAuthorize that
    // EXCLUDES AGENT_SERVICE. The only legitimate agent path for these writes
    // is the Phase-3 in-process marker flow via the action handlers. Direct
    // OpenClaw bypass via X-API-Key is blocked here.

    private final DealService service;
    private final ResponseFormatter responseFormatter;

    public DealController(DealService service, ResponseFormatter responseFormatter) {
        this.service = service;
        this.responseFormatter = responseFormatter;
    }

    // ── List / Search ────────────────────────────────────────────────

    @GetMapping
    @DealerScoped
    public ResponseEntity<PaginatedResponse<DealResponse>> list(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing deals - dealer: {}, status: {}, page: {}, size: {}", dealerCode, status, page, size);
        PageRequest pageRequest = PageRequest.of(page, Math.min(size, 100));
        PaginatedResponse<DealResponse> result = service.findAll(dealerCode, status, pageRequest);
        return ResponseEntity.ok(result);
    }

    // ── Get Single Deal ──────────────────────────────────────────────

    @GetMapping("/{dealNumber}")
    public ResponseEntity<ApiResponse<DealResponse>> getByDealNumber(@PathVariable String dealNumber) {
        log.info("Getting deal: {}", dealNumber);
        DealResponse response = service.findByDealNumber(dealNumber);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // ── Create Worksheet ─────────────────────────────────────────────

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<DealResponse>> create(@Valid @RequestBody CreateDealRequest request) {
        log.info("Creating deal worksheet - customer: {}, VIN: {}, dealer: {}",
                request.getCustomerId(), request.getVin(), request.getDealerCode());
        DealResponse response = service.createDeal(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Deal worksheet created successfully"));
    }

    // ── Negotiate ────────────────────────────────────────────────────

    @PostMapping("/{dealNumber}/negotiate")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<NegotiationResponse>> negotiate(
            @PathVariable String dealNumber,
            @Valid @RequestBody NegotiationRequest request) {
        log.info("Negotiating deal: {} - action: {}", dealNumber, request.getAction());
        NegotiationResponse response = service.negotiate(dealNumber, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Negotiation applied successfully"));
    }

    // ── Validate ─────────────────────────────────────────────────────

    @PostMapping("/{dealNumber}/validate")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<ValidationResponse>> validate(@PathVariable String dealNumber) {
        log.info("Validating deal: {}", dealNumber);
        ValidationResponse response = service.validate(dealNumber);
        return ResponseEntity.ok(responseFormatter.success(response, "Deal validation complete"));
    }

    // ── Approve / Reject ─────────────────────────────────────────────

    @PostMapping("/{dealNumber}/approve")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
    public ResponseEntity<ApiResponse<ApprovalResponse>> approve(
            @PathVariable String dealNumber,
            @Valid @RequestBody ApprovalRequest request) {
        log.info("Approval action on deal: {} - action: {}", dealNumber, request.getAction());
        ApprovalResponse response = service.approve(dealNumber, request);
        String message = "APPROVE".equals(request.getAction()) ? "Deal approved" : "Deal rejected";
        return ResponseEntity.ok(responseFormatter.success(response, message));
    }

    // ── Trade-In ─────────────────────────────────────────────────────

    @PostMapping("/{dealNumber}/trade-in")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<TradeInResponse>> addTradeIn(
            @PathVariable String dealNumber,
            @Valid @RequestBody TradeInRequest request) {
        log.info("Adding trade-in to deal: {} - VIN: {}", dealNumber, request.getVin());
        TradeInResponse response = service.addTradeIn(dealNumber, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Trade-in added successfully"));
    }

    // ── Apply Incentives ─────────────────────────────────────────────

    @PostMapping("/{dealNumber}/incentives")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<DealResponse>> applyIncentives(
            @PathVariable String dealNumber,
            @Valid @RequestBody ApplyIncentivesRequest request) {
        log.info("Applying incentives to deal: {} - count: {}", dealNumber,
                request.getIncentiveIds() != null ? request.getIncentiveIds().size() : 0);
        DealResponse response = service.applyIncentives(dealNumber, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Incentives applied successfully"));
    }

    // ── Complete Sale ────────────────────────────────────────────────

    @PostMapping("/{dealNumber}/complete")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<DealResponse>> complete(
            @PathVariable String dealNumber,
            @Valid @RequestBody CompletionRequest request) {
        log.info("Completing deal: {}", dealNumber);
        DealResponse response = service.completeDeal(dealNumber, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Deal completed - vehicle delivered"));
    }

    // ── Cancel / Unwind ──────────────────────────────────────────────

    @PostMapping("/{dealNumber}/cancel")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','OPERATOR')")
    public ResponseEntity<ApiResponse<DealResponse>> cancel(
            @PathVariable String dealNumber,
            @Valid @RequestBody CancellationRequest request) {
        log.info("Cancelling deal: {} - reason: {}", dealNumber, request.getReason());
        DealResponse response = service.cancelDeal(dealNumber, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Deal cancelled"));
    }
}
