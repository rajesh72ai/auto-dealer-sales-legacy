package com.autosales.modules.admin.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemConfigResponse {

    private String configKey;
    private String configValue;
    private String configDesc;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;
}
