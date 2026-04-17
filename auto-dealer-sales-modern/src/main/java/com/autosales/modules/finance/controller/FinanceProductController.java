package com.autosales.modules.finance.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.finance.dto.FinanceProductRequest;
import com.autosales.modules.finance.dto.FinanceProductResponse;
import com.autosales.modules.finance.service.FinanceProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for F&I product catalog and selection.
 * Port of FINPRD00.cbl — F&I product menu presentation and selection.
 */
@RestController
@RequestMapping("/api/finance/products")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','OPERATOR','AGENT_SERVICE')")
@Slf4j
@RequiredArgsConstructor
public class FinanceProductController {

    private final FinanceProductService financeProductService;
    private final ResponseFormatter responseFormatter;

    // -- Get Product Catalog --------------------------------------------------

    @GetMapping("/{dealNumber}")
    public ResponseEntity<ApiResponse<FinanceProductResponse>> getProductCatalog(
            @PathVariable String dealNumber) {
        log.info("Getting F&I product catalog for deal: {}", dealNumber);
        FinanceProductResponse response = financeProductService.getProductCatalog(dealNumber);
        return ResponseEntity.ok(responseFormatter.success(response));
    }

    // -- Select Products ------------------------------------------------------

    @PostMapping
    public ResponseEntity<ApiResponse<FinanceProductResponse>> selectProducts(
            @Valid @RequestBody FinanceProductRequest request) {
        log.info("Selecting F&I products for deal: {}, product count: {}",
                request.getDealNumber(), request.getSelectedProducts() != null ? request.getSelectedProducts().size() : 0);
        FinanceProductResponse response = financeProductService.selectProducts(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(responseFormatter.success(response, "F&I products selected successfully"));
    }
}
