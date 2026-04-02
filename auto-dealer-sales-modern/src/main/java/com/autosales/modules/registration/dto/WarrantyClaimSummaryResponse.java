package com.autosales.modules.registration.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WarrantyClaimSummaryResponse {

    private String dealerCode;
    private String fromDate;
    private String toDate;
    private List<ClaimTypeSummary> byType;
    private int grandTotalClaims;
    private BigDecimal grandTotalLabor;
    private BigDecimal grandTotalParts;
    private BigDecimal grandTotal;
    private BigDecimal averageClaimAmount;
    private int totalApproved;
    private int totalDenied;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ClaimTypeSummary {
        private String claimType;
        private String claimTypeName;
        private int totalClaims;
        private BigDecimal laborTotal;
        private BigDecimal partsTotal;
        private BigDecimal claimTotal;
        private int approvedCount;
        private int deniedCount;
    }
}
