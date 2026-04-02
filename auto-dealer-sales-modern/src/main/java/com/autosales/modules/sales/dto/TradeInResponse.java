package com.autosales.modules.sales.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Trade-in details response with calculated ACV and net trade values.
 * Port of SLSTRD00.cbl — trade-in appraisal result display area.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeInResponse {

    private Integer tradeId;
    private String dealNumber;
    private String vin;
    private Short tradeYear;
    private String tradeMake;
    private String tradeModel;
    private String tradeColor;
    private Integer odometer;
    private String conditionCode;
    private String conditionDescription;    // Excellent, Good, Fair, Poor

    // --- Calculated values ---
    private BigDecimal acvAmount;           // actual cash value based on condition
    private BigDecimal overAllow;
    private BigDecimal allowanceAmt;        // ACV + overAllow
    private BigDecimal payoffAmt;
    private BigDecimal netTrade;            // allowance - payoff

    // --- Payoff details ---
    private String payoffBank;
    private String payoffAcct;

    // --- Appraisal ---
    private String appraisedBy;
    private LocalDateTime appraisedTs;

    // --- Formatted display ---
    private String formattedAcv;
    private String formattedAllowance;
    private String formattedNetTrade;
}
