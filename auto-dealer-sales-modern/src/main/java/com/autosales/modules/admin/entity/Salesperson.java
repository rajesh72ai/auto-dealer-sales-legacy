package com.autosales.modules.admin.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "salesperson")
public class Salesperson {

    @Id
    @Column(name = "salesperson_id", length = 8)
    private String salespersonId;

    @Column(name = "salesperson_name", nullable = false, length = 30)
    private String salespersonName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "dealer_code", nullable = false)
    private Dealer dealer;

    @Column(name = "hire_date")
    private LocalDate hireDate;

    @Column(name = "termination_date")
    private LocalDate terminationDate;

    @Column(name = "commission_plan", nullable = false, length = 2)
    private String commissionPlan;

    @Column(name = "active_flag", nullable = false, length = 1)
    private String activeFlag;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
