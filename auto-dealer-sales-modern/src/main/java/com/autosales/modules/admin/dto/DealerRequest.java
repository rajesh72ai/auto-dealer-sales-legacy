package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealerRequest {

    @NotBlank @Size(max = 5)
    private String dealerCode;

    @NotBlank @Size(max = 60)
    private String dealerName;

    @NotBlank @Size(max = 50)
    private String addressLine1;

    @Size(max = 50)
    private String addressLine2;

    @NotBlank @Size(max = 30)
    private String city;

    @NotBlank @Size(min = 2, max = 2)
    private String stateCode;

    @NotBlank @Size(max = 10)
    private String zipCode;

    @NotBlank @Pattern(regexp = "\\d{10}", message = "Phone must be 10 digits")
    private String phoneNumber;

    @Pattern(regexp = "\\d{10}", message = "Fax must be 10 digits")
    private String faxNumber;

    @NotBlank @Size(max = 40)
    private String dealerPrincipal;

    @NotBlank @Size(max = 3)
    private String regionCode;

    @NotBlank @Size(max = 2)
    private String zoneCode;

    @NotBlank @Size(max = 10)
    private String oemDealerNum;

    @Size(max = 5)
    private String floorPlanLenderId;

    @NotNull @Min(1)
    private Short maxInventory;

    @NotBlank @Pattern(regexp = "[YN]")
    private String activeFlag;

    @NotNull
    private LocalDate openedDate;
}
