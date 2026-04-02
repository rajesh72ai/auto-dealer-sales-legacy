package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModelMasterRequest {

    @NotNull @Min(1990) @Max(2030)
    private Short modelYear;

    @NotBlank @Size(max = 3)
    private String makeCode;

    @NotBlank @Size(max = 6)
    private String modelCode;

    @NotBlank @Size(max = 40)
    private String modelName;

    @NotBlank @Pattern(regexp = "SD|SV|TK|CP|HB|VN|CV")
    private String bodyStyle;

    @NotBlank @Size(max = 3)
    private String trimLevel;

    @NotBlank @Pattern(regexp = "GAS|DSL|HYB|EV")
    private String engineType;

    @NotBlank @Pattern(regexp = "[AMCD]")
    private String transmission;

    @NotBlank @Pattern(regexp = "FWD|RWD|AWD|4WD")
    private String driveTrain;

    @Size(max = 200)
    private String exteriorColors;

    @Size(max = 200)
    private String interiorColors;

    private Integer curbWeight;

    private Short fuelEconomyCity;

    private Short fuelEconomyHwy;

    @NotBlank @Pattern(regexp = "[YN]")
    private String activeFlag;
}
