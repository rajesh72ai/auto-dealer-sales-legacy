package com.autosales.modules.batch.dto;

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
public class BatchJobResponse {

    private String programId;
    private String programName;
    private LocalDate lastRunDate;
    private LocalDate lastSyncDate;
    private Integer recordsProcessed;
    private String runStatus;
    private String statusDescription;
    private LocalDateTime createdTs;
    private LocalDateTime updatedTs;
}
