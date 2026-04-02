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
@Table(name = "registration")
public class Registration {

    @Id
    @Column(name = "reg_id", length = 12)
    private String regId;

    @Column(name = "deal_number", nullable = false, length = 10)
    private String dealNumber;

    @Column(name = "vin", nullable = false, length = 17)
    private String vin;

    @Column(name = "customer_id", nullable = false)
    private Integer customerId;

    @Column(name = "reg_state", nullable = false, length = 2)
    private String regState;

    @Column(name = "reg_type", nullable = false, length = 2)
    private String regType;

    @Column(name = "plate_number", length = 10)
    private String plateNumber;

    @Column(name = "title_number", length = 20)
    private String titleNumber;

    @Column(name = "lien_holder", length = 60)
    private String lienHolder;

    @Column(name = "lien_holder_addr", length = 100)
    private String lienHolderAddr;

    @Column(name = "reg_status", nullable = false, length = 2)
    private String regStatus;

    @Column(name = "submission_date")
    private LocalDate submissionDate;

    @Column(name = "issued_date")
    private LocalDate issuedDate;

    @Column(name = "reg_fee_paid", nullable = false, precision = 7, scale = 2)
    private BigDecimal regFeePaid;

    @Column(name = "title_fee_paid", nullable = false, precision = 7, scale = 2)
    private BigDecimal titleFeePaid;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
