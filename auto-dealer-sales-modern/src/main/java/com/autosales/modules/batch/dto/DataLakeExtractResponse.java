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
public class DataLakeExtractResponse {

    private LocalDateTime extractedAt;
    private Integer totalRecords;
    private Integer errorCount;
    private List<DataLakeRecord> records;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DataLakeRecord {
        private String tableName;
        private String keyValue;
        private String actionType;
        private LocalDateTime auditTs;
        private String payload;
    }
}
