package com.autosales.modules.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemConfigRequest {

    @NotBlank @Size(max = 100)
    private String configValue;

    @Size(max = 60)
    private String configDesc;
}
