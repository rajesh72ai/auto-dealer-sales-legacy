package com.autosales.modules.registration.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegistrationResponse {

    private String regId;
    private String dealNumber;
    private String vin;
    private Integer customerId;
    private String regState;
    private String regType;
    private String plateNumber;
    private String titleNumber;
    private String lienHolder;
    private String lienHolderAddr;
    private String regStatus;
    private LocalDate submissionDate;
    private LocalDate issuedDate;
    private BigDecimal regFeePaid;
    private BigDecimal titleFeePaid;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private String regTypeName;
    private String regStatusName;
    private String formattedRegFee;
    private String formattedTitleFee;
    private List<TitleStatusResponse> statusHistory;
}
