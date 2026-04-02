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
@Table(name = "price_master")
@IdClass(PriceMasterId.class)
public class PriceMaster {

    @Id
    @Column(name = "model_year")
    private Short modelYear;

    @Id
    @Column(name = "make_code", length = 3)
    private String makeCode;

    @Id
    @Column(name = "model_code", length = 6)
    private String modelCode;

    @Id
    @Column(name = "effective_date")
    private LocalDate effectiveDate;

    @Column(name = "msrp", nullable = false, precision = 11, scale = 2)
    private BigDecimal msrp;

    @Column(name = "invoice_price", nullable = false, precision = 11, scale = 2)
    private BigDecimal invoicePrice;

    @Column(name = "holdback_amt", nullable = false, precision = 9, scale = 2)
    private BigDecimal holdbackAmt;

    @Column(name = "holdback_pct", nullable = false, precision = 5, scale = 3)
    private BigDecimal holdbackPct;

    @Column(name = "destination_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal destinationFee;

    @Column(name = "advertising_fee", nullable = false, precision = 7, scale = 2)
    private BigDecimal advertisingFee;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;
}
