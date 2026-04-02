package com.autosales.modules.registration.dto;

import lombok.*;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecallNotificationResponse {

    private Integer notifId;
    private String recallId;
    private String vin;
    private Integer customerId;
    private String notifType;
    private LocalDate notifDate;
    private String responseFlag;

    // Computed fields
    private String notifTypeName;
}
