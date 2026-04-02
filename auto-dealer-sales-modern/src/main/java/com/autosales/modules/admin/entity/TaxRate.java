package com.autosales.modules.admin.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "tax_rate")
@IdClass(TaxRateId.class)
public class TaxRate {

    @Id
    @Column(name = "state_code", length = 2)
    private String stateCode;

    @Id
    @Column(name = "county_code", length = 5)
    private String countyCode;

    @Id
    @Column(name = "city_code", length = 5)
    private String cityCode;

    @Id
    @Column(name = "effective_date")
    private LocalDate effectiveDate;

    @Column(name = "state_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal stateRate;

    @Column(name = "county_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal countyRate;

    @Column(name = "city_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal cityRate;

    @Column(name = "doc_fee_max", nullable = false, precision = 7, scale = 2)
    private BigDecimal docFeeMax;

    @Column(name = "title_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal titleFee;

    @Column(name = "reg_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal regFee;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;
}
