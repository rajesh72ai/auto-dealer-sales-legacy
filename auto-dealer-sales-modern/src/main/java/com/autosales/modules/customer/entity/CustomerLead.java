package com.autosales.modules.customer.entity;

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
@Table(name = "customer_lead")
public class CustomerLead {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "lead_id")
    private Integer leadId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Column(name = "dealer_code", nullable = false, length = 5)
    private String dealerCode;

    @Column(name = "lead_source", nullable = false, length = 3)
    private String leadSource;

    @Column(name = "interest_model", length = 6)
    private String interestModel;

    @Column(name = "interest_year")
    private Short interestYear;

    @Column(name = "lead_status", nullable = false, length = 2)
    private String leadStatus;

    @Column(name = "assigned_sales", nullable = false, length = 8)
    private String assignedSales;

    @Column(name = "follow_up_date")
    private LocalDate followUpDate;

    @Column(name = "last_contact_dt")
    private LocalDate lastContactDt;

    @Column(name = "contact_count", nullable = false)
    private Short contactCount;

    @Column(name = "notes", length = 200)
    private String notes;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
