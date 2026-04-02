package com.autosales.modules.batch.entity;

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
@Table(name = "batch_checkpoint")
@IdClass(BatchCheckpointId.class)
public class BatchCheckpoint {

    @Id
    @Column(name = "program_id", length = 8)
    private String programId;

    @Id
    @Column(name = "checkpoint_seq")
    private Integer checkpointSeq;

    @Column(name = "checkpoint_timestamp", nullable = false)
    private LocalDateTime checkpointTimestamp;

    @Column(name = "last_key_value", length = 30)
    private String lastKeyValue;

    @Column(name = "records_in", nullable = false)
    private Integer recordsIn;

    @Column(name = "records_out", nullable = false)
    private Integer recordsOut;

    @Column(name = "records_error", nullable = false)
    private Integer recordsError;

    @Column(name = "checkpoint_status", nullable = false, length = 2)
    private String checkpointStatus;
}
