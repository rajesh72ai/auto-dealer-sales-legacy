package com.autosales.modules.batch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DmsExtractResponse {

    private LocalDateTime extractedAt;
    private Integer dealersProcessed;
    private Integer inventoryRecords;
    private Integer dealRecords;
    private List<DmsDealerBlock> dealers;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DmsDealerBlock {
        private String dealerCode;
        private String dealerName;
        private List<DmsInventoryRecord> inventory;
        private List<DmsDealRecord> deals;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DmsInventoryRecord {
        private String vin;
        private String makeCode;
        private String modelCode;
        private Short modelYear;
        private String exteriorColor;
        private String vehicleStatus;
        private Short daysInStock;
        private BigDecimal msrp;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DmsDealRecord {
        private String dealNumber;
        private String customerName;
        private String vin;
        private String dealType;
        private String dealStatus;
        private BigDecimal totalPrice;
        private LocalDate dealDate;
    }
}
