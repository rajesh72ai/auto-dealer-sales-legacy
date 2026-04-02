package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "vehicle_option")
@IdClass(VehicleOptionId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleOption {

    @Id
    @Column(name = "vin")
    private String vin;

    @Id
    @Column(name = "option_code")
    private String optionCode;

    @Column(name = "option_desc", nullable = false)
    private String optionDesc;

    @Column(name = "option_price", nullable = false)
    private BigDecimal optionPrice;

    @Column(name = "installed_flag", nullable = false)
    private String installedFlag;
}
