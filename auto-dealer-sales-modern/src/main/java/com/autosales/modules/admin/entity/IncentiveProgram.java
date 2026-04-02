package com.autosales.modules.admin.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "incentive_program")
public class IncentiveProgram {

    @Id
    @Column(name = "incentive_id", length = 10)
    private String incentiveId;

    @Column(name = "incentive_name", nullable = false, length = 60)
    private String incentiveName;

    @Column(name = "incentive_type", nullable = false, length = 2)
    private String incentiveType;

    @Column(name = "model_year")
    private Short modelYear;

    @Column(name = "make_code", length = 3)
    private String makeCode;

    @Column(name = "model_code", length = 6)
    private String modelCode;

    @Column(name = "region_code", length = 3)
    private String regionCode;

    @Column(name = "amount", nullable = false, precision = 9, scale = 2)
    private BigDecimal amount;

    @Column(name = "rate_override", precision = 5, scale = 3)
    private BigDecimal rateOverride;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "max_units")
    private Integer maxUnits;

    @Column(name = "units_used", nullable = false)
    private Integer unitsUsed;

    @Column(name = "stackable_flag", nullable = false, length = 1)
    private String stackableFlag;

    @Column(name = "active_flag", nullable = false, length = 1)
    private String activeFlag;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;
}
