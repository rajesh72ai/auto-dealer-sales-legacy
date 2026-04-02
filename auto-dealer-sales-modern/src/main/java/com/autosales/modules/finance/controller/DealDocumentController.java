package com.autosales.modules.finance.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.finance.dto.DealDocumentResponse;
import com.autosales.modules.finance.service.DealDocumentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for deal document generation.
 * Port of FINDOC00.cbl — finance document assembly (RIC, lease agreement, cash receipt).
 */
@RestController
@RequestMapping("/api/finance/documents")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','FINANCE','SALESPERSON')")
@Slf4j
@RequiredArgsConstructor
public class DealDocumentController {

    private final DealDocumentService dealDocumentService;
    private final ResponseFormatter responseFormatter;

    // -- Generate Document ----------------------------------------------------

    @GetMapping("/{dealNumber}")
    public ResponseEntity<ApiResponse<DealDocumentResponse>> generateDocument(
            @PathVariable String dealNumber) {
        log.info("Generating deal document for deal: {}", dealNumber);
        DealDocumentResponse response = dealDocumentService.generateDocument(dealNumber);
        return ResponseEntity.ok(responseFormatter.success(response));
    }
}
