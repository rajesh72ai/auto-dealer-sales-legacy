package com.autosales.modules.admin.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PriceMasterId implements Serializable {

    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private LocalDate effectiveDate;
}
