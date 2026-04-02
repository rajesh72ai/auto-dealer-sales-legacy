package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InboundProcessingResponse {

    private LocalDateTime processedAt;
    private Integer totalRecords;
    private Integer accepted;
    private Integer rejected;
    private List<RejectedRecord> rejections;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RejectedRecord {
        private String vin;
        private String reasonCode;
        private String description;
    }
}
