package com.autosales.modules.registration.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TitleStatusResponse {

    private String regId;
    private Short statusSeq;
    private String statusCode;
    private String statusDesc;
    private LocalDateTime statusTs;
    private String statusName;
}
