package com.autosales.modules.vehicle.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "transit_status")
@IdClass(TransitStatusId.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransitStatus {

    @Id
    @Column(name = "vin")
    private String vin;

    @Id
    @Column(name = "status_seq")
    private Integer statusSeq;

    @Column(name = "location_desc", nullable = false)
    private String locationDesc;

    @Column(name = "status_code", nullable = false)
    private String statusCode;

    @Column(name = "edi_ref_num")
    private String ediRefNum;

    @Column(name = "status_ts", nullable = false)
    private LocalDateTime statusTs;

    @Column(name = "received_ts", nullable = false)
    private LocalDateTime receivedTs;
}
