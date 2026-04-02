package com.autosales.modules.registration.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "recall_notification")
public class RecallNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notif_id")
    private Integer notifId;

    @Column(name = "recall_id", nullable = false, length = 10)
    private String recallId;

    @Column(name = "vin", nullable = false, length = 17)
    private String vin;

    @Column(name = "customer_id")
    private Integer customerId;

    @Column(name = "notif_type", nullable = false, length = 1)
    private String notifType;

    @Column(name = "notif_date", nullable = false)
    private LocalDate notifDate;

    @Column(name = "response_flag", nullable = false, length = 1)
    private String responseFlag;
}
