package com.autosales.modules.batch.entity;

import jakarta.persistence.*;
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
@Entity
@Table(name = "batch_control")
public class BatchControl {

    @Id
    @Column(name = "program_id", length = 8)
    private String programId;

    @Column(name = "last_run_date")
    private LocalDate lastRunDate;

    @Column(name = "last_sync_date")
    private LocalDate lastSyncDate;

    @Column(name = "records_processed", nullable = false)
    private Integer recordsProcessed;

    @Column(name = "run_status", nullable = false, length = 2)
    private String runStatus;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
