package com.autosales.modules.admin.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealerResponse {

    private String dealerCode;
    private String dealerName;
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String stateCode;
    private String zipCode;
    private String phoneNumber;
    private String faxNumber;
    private String dealerPrincipal;
    private String regionCode;
    private String zoneCode;
    private String oemDealerNum;
    private String floorPlanLenderId;
    private Short maxInventory;
    private String activeFlag;
    private LocalDate openedDate;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;

    // Computed fields
    private String formattedPhone;
    private String formattedFax;
}
