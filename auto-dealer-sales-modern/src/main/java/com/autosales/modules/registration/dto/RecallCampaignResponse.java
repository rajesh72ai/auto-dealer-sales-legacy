package com.autosales.modules.registration.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecallCampaignResponse {

    private String recallId;
    private String nhtsaNum;
    private String recallDesc;
    private String severity;
    private String affectedYears;
    private String affectedModels;
    private String remedyDesc;
    private LocalDate remedyAvailDt;
    private LocalDate announcedDate;
    private Integer totalAffected;
    private Integer totalCompleted;
    private String campaignStatus;
    private LocalDateTime createdTs;

    // Computed fields
    private String severityName;
    private String campaignStatusName;
    private double completionPercentage;
}
