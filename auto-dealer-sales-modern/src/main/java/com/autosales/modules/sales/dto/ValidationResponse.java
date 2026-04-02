package com.autosales.modules.sales.dto;

import lombok.*;

import java.util.List;

/**
 * Deal validation result response.
 * Port of SLSVAL00.cbl — sales deal validation transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidationResponse {

    private String dealNumber;
    private boolean valid;
    private String result;          // "DEAL VALID" or "VALIDATION FAILED"
    private List<String> errors;    // up to 10 error messages
    private String newStatus;       // PA if valid, unchanged if not
}
