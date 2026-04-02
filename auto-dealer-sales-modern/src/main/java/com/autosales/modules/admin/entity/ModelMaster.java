package com.autosales.modules.admin.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "model_master")
@IdClass(ModelMasterId.class)
public class ModelMaster {

    @Id
    @Column(name = "model_year")
    private Short modelYear;

    @Id
    @Column(name = "make_code", length = 3)
    private String makeCode;

    @Id
    @Column(name = "model_code", length = 6)
    private String modelCode;

    @Column(name = "model_name", nullable = false, length = 40)
    private String modelName;

    @Column(name = "body_style", nullable = false, length = 2)
    private String bodyStyle;

    @Column(name = "trim_level", nullable = false, length = 3)
    private String trimLevel;

    @Column(name = "engine_type", nullable = false, length = 3)
    private String engineType;

    @Column(name = "transmission", nullable = false, length = 1)
    private String transmission;

    @Column(name = "drive_train", nullable = false, length = 3)
    private String driveTrain;

    @Column(name = "exterior_colors", length = 200)
    private String exteriorColors;

    @Column(name = "interior_colors", length = 200)
    private String interiorColors;

    @Column(name = "curb_weight")
    private Integer curbWeight;

    @Column(name = "fuel_economy_city")
    private Short fuelEconomyCity;

    @Column(name = "fuel_economy_hwy")
    private Short fuelEconomyHwy;

    @Column(name = "active_flag", nullable = false, length = 1)
    private String activeFlag;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;
}
