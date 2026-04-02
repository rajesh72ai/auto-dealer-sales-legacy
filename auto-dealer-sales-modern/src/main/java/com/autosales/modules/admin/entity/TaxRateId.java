package com.autosales.modules.admin.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TaxRateId implements Serializable {

    private String stateCode;
    private String countyCode;
    private String cityCode;
    private LocalDate effectiveDate;
}
