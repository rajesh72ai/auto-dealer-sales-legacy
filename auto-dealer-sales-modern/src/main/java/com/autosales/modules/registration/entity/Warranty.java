package com.autosales.modules.registration.entity;

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
@Table(name = "warranty")
public class Warranty {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "warranty_id")
    private Integer warrantyId;

    @Column(name = "vin", nullable = false, length = 17)
    private String vin;

    @Column(name = "deal_number", nullable = false, length = 10)
    private String dealNumber;

    @Column(name = "warranty_type", nullable = false, length = 2)
    private String warrantyType;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "expiry_date", nullable = false)
    private LocalDate expiryDate;

    @Column(name = "mileage_limit", nullable = false)
    private Integer mileageLimit;

    @Column(name = "deductible", nullable = false, precision = 7, scale = 2)
    private BigDecimal deductible;

    @Column(name = "active_flag", nullable = false, length = 1)
    private String activeFlag;

    @Column(name = "registered_ts", nullable = false)
    private LocalDateTime registeredTs;
}
