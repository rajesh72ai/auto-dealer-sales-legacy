package com.autosales.modules.customer.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerResponse {

    private Integer customerId;
    private String firstName;
    private String lastName;
    private String middleInit;
    private LocalDate dateOfBirth;
    private String ssnLast4;
    private String driversLicense;
    private String dlState;
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String stateCode;
    private String zipCode;
    private String homePhone;
    private String cellPhone;
    private String email;
    private String employerName;
    private BigDecimal annualIncome;
    private String customerType;
    private String sourceCode;
    private String dealerCode;
    private String assignedSales;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private String formattedPhone;
    private String formattedCellPhone;
    private String fullName;
}
