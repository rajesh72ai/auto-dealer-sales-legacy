package com.autosales.modules.admin.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "lender")
public class Lender {

    @Id
    @Column(name = "lender_id", length = 5)
    private String lenderId;

    @Column(name = "lender_name", nullable = false, length = 40)
    private String lenderName;

    @Column(name = "contact_name", length = 40)
    private String contactName;

    @Column(name = "phone", length = 10)
    private String phone;

    @Column(name = "address_line1", length = 50)
    private String addressLine1;

    @Column(name = "city", length = 30)
    private String city;

    @Column(name = "state_code", length = 2)
    private String stateCode;

    @Column(name = "zip_code", length = 10)
    private String zipCode;

    @Column(name = "lender_type", nullable = false, length = 2)
    private String lenderType;

    @Column(name = "base_rate", nullable = false, precision = 5, scale = 3)
    private BigDecimal baseRate;

    @Column(name = "spread", nullable = false, precision = 5, scale = 3)
    private BigDecimal spread;

    @Column(name = "curtailment_days", nullable = false)
    private Integer curtailmentDays;

    @Column(name = "free_floor_days", nullable = false)
    private Integer freeFloorDays;

    @Column(name = "active_flag", nullable = false, length = 1)
    private String activeFlag;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;
}
