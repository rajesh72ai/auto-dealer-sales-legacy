package com.autosales.modules.vehicle.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.vehicle.dto.TransferApprovalRequest;
import com.autosales.modules.vehicle.dto.TransferRequest;
import com.autosales.modules.vehicle.dto.TransferResponse;
import com.autosales.modules.vehicle.service.StockTransferService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for dealer-to-dealer stock transfer operations.
 * Port of VEHTRN00.cbl / STKTRN00.cbl — transfer request, approval, and completion.
 */
@RestController
@RequestMapping("/api/stock/transfers")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class StockTransferController {

    private final StockTransferService service;
    private final ResponseFormatter responseFormatter;

    @PostMapping
    public ResponseEntity<ApiResponse<TransferResponse>> requestTransfer(
            @Valid @RequestBody TransferRequest request) {
        log.info("POST /api/stock/transfers — vin={}, from={}, to={}",
                request.getVin(), request.getFromDealer(), request.getToDealer());
        TransferResponse response = service.requestTransfer(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Transfer requested successfully"));
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<TransferResponse>> listTransfers(
            @RequestParam String dealerCode,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/stock/transfers — dealer={}, status={}, page={}, size={}", dealerCode, status, page, size);
        PaginatedResponse<TransferResponse> response = service.listTransfers(dealerCode, status, page, size);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TransferResponse>> getTransfer(@PathVariable int id) {
        log.info("GET /api/stock/transfers/{}", id);
        TransferResponse response = service.getTransfer(id);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<TransferResponse>> approveTransfer(
            @PathVariable int id,
            @Valid @RequestBody TransferApprovalRequest request) {
        log.info("POST /api/stock/transfers/{}/approve — approvedBy={}", id, request.getApprovedBy());
        TransferResponse response = service.approveTransfer(id, request);
        return ResponseEntity.ok(responseFormatter.success(response, "Transfer approved successfully"));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<TransferResponse>> completeTransfer(@PathVariable int id) {
        log.info("POST /api/stock/transfers/{}/complete", id);
        TransferResponse response = service.completeTransfer(id);
        return ResponseEntity.ok(responseFormatter.success(response, "Transfer completed successfully"));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<TransferResponse>> cancelTransfer(@PathVariable int id) {
        log.info("POST /api/stock/transfers/{}/cancel", id);
        TransferResponse response = service.cancelTransfer(id);
        return ResponseEntity.ok(responseFormatter.success(response, "Transfer cancelled successfully"));
    }
}
