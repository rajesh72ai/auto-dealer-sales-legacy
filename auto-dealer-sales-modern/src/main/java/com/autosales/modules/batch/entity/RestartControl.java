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
@Table(name = "restart_control")
@IdClass(RestartControlId.class)
public class RestartControl {

    @Id
    @Column(name = "job_name", length = 8)
    private String jobName;

    @Id
    @Column(name = "step_name", length = 8)
    private String stepName;

    @Column(name = "checkpoint_id", nullable = false, length = 20)
    private String checkpointId;

    @Column(name = "records_processed", nullable = false)
    private Integer recordsProcessed;

    @Column(name = "last_key_value", length = 50)
    private String lastKeyValue;

    @Column(name = "restart_flag", nullable = false, length = 1)
    private String restartFlag;

    @Column(name = "status", nullable = false, length = 1)
    private String status;

    @Column(name = "started_ts", nullable = false)
    private LocalDateTime startedTs;

    @Column(name = "checkpoint_ts", nullable = false)
    private LocalDateTime checkpointTs;

    @Column(name = "completed_ts")
    private LocalDateTime completedTs;
}
