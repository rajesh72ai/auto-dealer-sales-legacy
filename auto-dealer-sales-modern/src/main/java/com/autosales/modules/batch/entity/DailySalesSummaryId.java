package com.autosales.modules.batch.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailySalesSummaryId implements Serializable {

    private LocalDate summaryDate;
    private String dealerCode;
    private Short modelYear;
    private String makeCode;
    private String modelCode;
}
