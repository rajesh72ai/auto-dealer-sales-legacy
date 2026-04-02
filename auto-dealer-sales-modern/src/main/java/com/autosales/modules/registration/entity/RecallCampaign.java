package com.autosales.modules.registration.entity;

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
@Table(name = "recall_campaign")
public class RecallCampaign {

    @Id
    @Column(name = "recall_id", length = 10)
    private String recallId;

    @Column(name = "nhtsa_num", length = 12)
    private String nhtsaNum;

    @Column(name = "recall_desc", nullable = false, length = 200)
    private String recallDesc;

    @Column(name = "severity", nullable = false, length = 1)
    private String severity;

    @Column(name = "affected_years", nullable = false, length = 40)
    private String affectedYears;

    @Column(name = "affected_models", nullable = false, length = 100)
    private String affectedModels;

    @Column(name = "remedy_desc", nullable = false, length = 200)
    private String remedyDesc;

    @Column(name = "remedy_avail_dt")
    private LocalDate remedyAvailDt;

    @Column(name = "announced_date", nullable = false)
    private LocalDate announcedDate;

    @Column(name = "total_affected", nullable = false)
    private Integer totalAffected;

    @Column(name = "total_completed", nullable = false)
    private Integer totalCompleted;

    @Column(name = "campaign_status", nullable = false, length = 1)
    private String campaignStatus;

    @Column(name = "created_ts", nullable = false)
    private LocalDateTime createdTs;
}
