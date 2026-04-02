package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommissionResponse {

    private Integer commissionId;
    private String dealerCode;
    private String salespersonId;
    private String dealNumber;
    private String commType;
    private BigDecimal grossAmount;
    private BigDecimal commRate;
    private BigDecimal commAmount;
    private String payPeriod;
    private String paidFlag;
    private LocalDateTime calcTs;
}
