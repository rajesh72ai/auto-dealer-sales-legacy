package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "lot_location")
@IdClass(LotLocationId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotLocation {

    @Id
    @Column(name = "dealer_code")
    private String dealerCode;

    @Id
    @Column(name = "location_code")
    private String locationCode;

    @Column(name = "location_desc", nullable = false)
    private String locationDesc;

    @Column(name = "location_type", nullable = false)
    private String locationType;

    @Column(name = "max_capacity", nullable = false)
    private Short maxCapacity;

    @Column(name = "current_count", nullable = false)
    private Short currentCount;

    @Column(name = "active_flag", nullable = false)
    private String activeFlag;
}
