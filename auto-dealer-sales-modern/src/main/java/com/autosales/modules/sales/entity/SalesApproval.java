package com.autosales.modules.sales.entity;

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
@Table(name = "sales_approval")
public class SalesApproval {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "approval_id")
    private Integer approvalId;

    @Column(name = "deal_number", nullable = false, length = 10)
    private String dealNumber;

    @Column(name = "approval_type", nullable = false, length = 2)
    private String approvalType;

    @Column(name = "approver_id", nullable = false, length = 8)
    private String approverId;

    @Column(name = "approval_status", nullable = false, length = 1)
    private String approvalStatus;

    @Column(name = "comments", length = 200)
    private String comments;

    @Column(name = "approval_ts", nullable = false)
    private LocalDateTime approvalTs;
}
