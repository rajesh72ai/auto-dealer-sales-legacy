package com.autosales.modules.customer.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeadResponse {

    private Integer leadId;
    private Integer customerId;
    private String customerName;
    private String dealerCode;
    private String leadSource;
    private String interestModel;
    private Short interestYear;
    private String leadStatus;
    private String assignedSales;
    private LocalDate followUpDate;
    private LocalDate lastContactDt;
    private Short contactCount;
    private String notes;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed field
    private boolean overdue;
}
