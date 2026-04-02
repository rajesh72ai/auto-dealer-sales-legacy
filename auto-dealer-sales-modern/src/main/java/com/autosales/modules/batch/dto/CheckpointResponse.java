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
public class CheckpointResponse {

    private String programId;
    private Integer checkpointSeq;
    private LocalDateTime checkpointTimestamp;
    private String lastKeyValue;
    private Integer recordsIn;
    private Integer recordsOut;
    private Integer recordsError;
    private String checkpointStatus;
}
