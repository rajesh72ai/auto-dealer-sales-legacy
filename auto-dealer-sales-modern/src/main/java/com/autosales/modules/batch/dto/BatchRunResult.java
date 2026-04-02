package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchRunResult {

    private String programId;
    private String status;
    private Integer recordsProcessed;
    private Integer recordsError;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private List<String> phases;
    private List<String> warnings;
}
