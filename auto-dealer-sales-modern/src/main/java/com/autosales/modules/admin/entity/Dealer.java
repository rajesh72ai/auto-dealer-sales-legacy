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
@Table(name = "dealer")
public class Dealer {

    @Id
    @Column(name = "dealer_code", length = 5)
    private String dealerCode;

    @Column(name = "dealer_name", nullable = false, length = 60)
    private String dealerName;

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

    @Column(name = "phone_number", nullable = false, length = 10)
    private String phoneNumber;

    @Column(name = "fax_number", length = 10)
    private String faxNumber;

    @Column(name = "dealer_principal", nullable = false, length = 40)
    private String dealerPrincipal;

    @Column(name = "region_code", nullable = false, length = 3)
    private String regionCode;

    @Column(name = "zone_code", nullable = false, length = 2)
    private String zoneCode;

    @Column(name = "oem_dealer_num", nullable = false, length = 10)
    private String oemDealerNum;

    @Column(name = "floor_plan_lender_id", length = 5)
    private String floorPlanLenderId;

    @Column(name = "max_inventory", nullable = false)
    private Short maxInventory;

    @Column(name = "active_flag", nullable = false, length = 1)
    private String activeFlag;

    @Column(name = "opened_date", nullable = false)
    private LocalDate openedDate;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
