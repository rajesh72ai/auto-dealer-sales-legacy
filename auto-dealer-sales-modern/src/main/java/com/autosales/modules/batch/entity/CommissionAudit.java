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
@Table(name = "commission_audit")
public class CommissionAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "audit_id")
    private Integer auditId;

    @Column(name = "deal_number", nullable = false, length = 10)
    private String dealNumber;

    @Column(name = "entity_type", nullable = false, length = 8)
    private String entityType;

    @Column(name = "description", nullable = false, length = 200)
    private String description;

    @Column(name = "audit_ts", nullable = false)
    private LocalDateTime auditTs;
}
