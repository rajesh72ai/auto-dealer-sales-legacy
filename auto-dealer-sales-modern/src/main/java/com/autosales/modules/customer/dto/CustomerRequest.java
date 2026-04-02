package com.autosales.modules.customer.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerRequest {

    @NotBlank @Size(max = 30)
    private String firstName;

    @NotBlank @Size(max = 30)
    private String lastName;

    @Size(max = 1)
    private String middleInit;

    private LocalDate dateOfBirth;

    @Size(max = 4)
    private String ssnLast4;

    @Size(max = 20)
    private String driversLicense;

    @Pattern(regexp = "[A-Z]{2}", message = "Driver's license state must be 2 uppercase letters")
    private String dlState;

    @NotBlank @Size(max = 50)
    private String addressLine1;

    @Size(max = 50)
    private String addressLine2;

    @NotBlank @Size(max = 30)
    private String city;

    @NotBlank @Pattern(regexp = "[A-Z]{2}", message = "State code must be 2 uppercase letters")
    private String stateCode;

    @NotBlank @Size(max = 10)
    private String zipCode;

    @Pattern(regexp = "\\d{10}", message = "Home phone must be 10 digits")
    private String homePhone;

    @Pattern(regexp = "\\d{10}", message = "Cell phone must be 10 digits")
    private String cellPhone;

    @Email(message = "Email must be a valid email address")
    private String email;

    @Size(max = 40)
    private String employerName;

    @DecimalMin(value = "0.00")
    private BigDecimal annualIncome;

    @NotBlank @Pattern(regexp = "[IBF]", message = "Customer type must be I (Individual), B (Business), or F (Fleet)")
    private String customerType;

    @Size(max = 3)
    private String sourceCode;

    @NotBlank @Size(max = 5)
    private String dealerCode;

    @Size(max = 8)
    private String assignedSales;
}
