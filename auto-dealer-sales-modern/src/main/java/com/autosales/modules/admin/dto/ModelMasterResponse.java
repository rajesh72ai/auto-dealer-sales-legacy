package com.autosales.modules.admin.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModelMasterResponse {

    private Short modelYear;
    private String makeCode;
    private String modelCode;
    private String modelName;
    private String bodyStyle;
    private String trimLevel;
    private String engineType;
    private String transmission;
    private String driveTrain;
    private String exteriorColors;
    private String interiorColors;
    private Integer curbWeight;
    private Short fuelEconomyCity;
    private Short fuelEconomyHwy;
    private String activeFlag;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;
}
