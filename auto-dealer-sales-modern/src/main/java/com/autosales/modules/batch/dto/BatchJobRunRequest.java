package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchJobRunRequest {

    private String dealerCode;
    private String payPeriod;
}
