package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurgeResultResponse {

    private LocalDateTime executedAt;
    private Integer registrationsArchived;
    private Integer auditLogsPurged;
    private Integer notificationsPurged;
    private String status;
}
