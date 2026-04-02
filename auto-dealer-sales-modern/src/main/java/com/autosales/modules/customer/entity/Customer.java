package com.autosales.modules.customer.entity;

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
@Table(name = "customer")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "customer_id")
    private Integer customerId;

    @Column(name = "first_name", nullable = false, length = 30)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 30)
    private String lastName;

    @Column(name = "middle_init", length = 1)
    private String middleInit;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(name = "ssn_last4", length = 4)
    private String ssnLast4;

    @Column(name = "drivers_license", length = 20)
    private String driversLicense;

    @Column(name = "dl_state", length = 2)
    private String dlState;

    @Column(name = "address_line1", nullable = false, length = 50)
    private String addressLine1;

    @Column(name = "address_line2", length = 50)
    private String addressLine2;

    @Column(name = "city", nullable = false, length = 30)
    private String city;

    @Column(name = "state_code", nullable = false, length = 2)
    private String stateCode;

    @Column(name = "zip_code", nullable = false, length = 10)
    private String zipCode;

    @Column(name = "home_phone", length = 10)
    private String homePhone;

    @Column(name = "cell_phone", length = 10)
    private String cellPhone;

    @Column(name = "email", length = 60)
    private String email;

    @Column(name = "employer_name", length = 40)
    private String employerName;

    @Column(name = "annual_income", precision = 11, scale = 2)
    private BigDecimal annualIncome;

    @Column(name = "customer_type", nullable = false, length = 1)
    private String customerType;

    @Column(name = "source_code", length = 3)
    private String sourceCode;

    @Column(name = "dealer_code", nullable = false, length = 5)
    private String dealerCode;

    @Column(name = "assigned_sales", length = 8)
    private String assignedSales;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
