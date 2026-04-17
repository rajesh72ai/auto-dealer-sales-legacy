package com.autosales.modules.finance.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.finance.dto.*;
import com.autosales.modules.finance.service.FinanceAppService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for finance application management.
 * Port of FINAPP00.cbl — finance application submission and processing
 *        FINAPV00.cbl — finance approval / decline workflow
 *        FINCAL00.cbl — loan payment calculator
 *        FINLSE00.cbl — lease payment calculator
 */
@RestController
@RequestMapping("/api/finance/applications")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','OPERATOR')")
@Slf4j
@RequiredArgsConstructor
public class FinanceAppController {

    private final FinanceAppService financeAppService;
    private final ResponseFormatter responseFormatter;

    // -- List / Search --------------------------------------------------------

    @GetMapping
    public ResponseEntity<PaginatedResponse<FinanceAppResponse>> listApplications(
            @RequestParam(required = false) String dealNumber,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String financeType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Listing finance applications - deal: {}, status: {}, type: {}, page: {}, size: {}",
                dealNumber, status, financeType, page, size);
        PaginatedResponse<FinanceAppResponse> result =
                financeAppService.listApplications(dealNumber, status, financeType, page, Math.min(size, 100));
        return ResponseEntity.ok(result);
    }

    // -- Get Single -----------------------------------------------------------

    @GetMapping("/{financeId}")
    public ResponseEntity<ApiResponse<FinanceAppResponse>> getApplication(@PathVariable String financeId) {
        log.info("Getting finance application: {}", financeId);
        FinanceAppResponse response = financeAppService.getApplication(financeId);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- Create Application ---------------------------------------------------

    @PostMapping
    public ResponseEntity<ApiResponse<FinanceAppResponse>> createApplication(
            @Valid @RequestBody FinanceAppRequest request) {
        log.info("Creating finance application - deal: {}, type: {}", request.getDealNumber(), request.getFinanceType());
        FinanceAppResponse response = financeAppService.createApplication(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "Finance application created successfully"));
    }

    // -- Approve / Decline ----------------------------------------------------

    @PostMapping("/approve")
    public ResponseEntity<ApiResponse<FinanceApprovalResponse>> approveOrDecline(
            @Valid @RequestBody FinanceApprovalRequest request) {
        log.info("Finance approval action - financeId: {}, action: {}", request.getFinanceId(), request.getAction());
        FinanceApprovalResponse response = financeAppService.approveOrDecline(request);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- Loan Calculator ------------------------------------------------------

    @PostMapping("/loan-calculator")
    public ResponseEntity<ApiResponse<LoanCalculatorResponse>> calculateLoan(
            @Valid @RequestBody LoanCalculatorRequest request) {
        log.info("Calculating loan - principal: {}, apr: {}, term: {}",
                request.getPrincipal(), request.getApr(), request.getTermMonths());
        LoanCalculatorResponse response = financeAppService.calculateLoan(request);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- Lease Calculator -----------------------------------------------------

    @PostMapping("/lease-calculator")
    public ResponseEntity<ApiResponse<LeaseCalculatorResponse>> calculateLease(
            @Valid @RequestBody LeaseCalculatorRequest request) {
        log.info("Calculating lease - capCost: {}, moneyFactor: {}, term: {}",
                request.getCapitalizedCost(), request.getMoneyFactor(), request.getTermMonths());
        LeaseCalculatorResponse response = financeAppService.calculateLease(request);
        return ResponseEntity.ok(responseFormatter.success(response));
    }
}
