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
@Table(name = "warranty_claim")
public class WarrantyClaim {

    @Id
    @Column(name = "claim_number", length = 8)
    private String claimNumber;

    @Column(name = "vin", nullable = false, length = 17)
    private String vin;

    @Column(name = "dealer_code", nullable = false, length = 5)
    private String dealerCode;

    @Column(name = "claim_type", nullable = false, length = 2)
    private String claimType;

    @Column(name = "claim_date", nullable = false)
    private LocalDate claimDate;

    @Column(name = "repair_date")
    private LocalDate repairDate;

    @Column(name = "labor_amt", nullable = false, precision = 9, scale = 2)
    private BigDecimal laborAmt;

    @Column(name = "parts_amt", nullable = false, precision = 9, scale = 2)
    private BigDecimal partsAmt;

    @Column(name = "total_claim", nullable = false, precision = 9, scale = 2)
    private BigDecimal totalClaim;

    @Column(name = "claim_status", nullable = false, length = 2)
    private String claimStatus;

    @Column(name = "technician_id", length = 8)
    private String technicianId;

    @Column(name = "repair_order_num", length = 12)
    private String repairOrderNum;

    @Column(name = "notes", length = 200)
    private String notes;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
