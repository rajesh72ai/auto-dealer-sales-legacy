package com.autosales.modules.registration.entity;

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
@Table(name = "title_status")
@IdClass(TitleStatusId.class)
public class TitleStatus {

    @Id
    @Column(name = "reg_id", length = 12)
    private String regId;

    @Id
    @Column(name = "status_seq")
    private Short statusSeq;

    @Column(name = "status_code", nullable = false, length = 2)
    private String statusCode;

    @Column(name = "status_desc", length = 60)
    private String statusDesc;

    @Column(name = "status_ts", nullable = false)
    private LocalDateTime statusTs;
}
