package com.autosales.modules.floorplan.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Floor plan vehicle detail response with computed aging and lender info.
 * Port of FPINQ00.cbl — floor plan vehicle inquiry transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FloorPlanVehicleResponse {

    // --- Entity fields ---
    private Integer floorPlanId;
    private String vin;
    private String dealerCode;
    private String lenderId;
    private String lenderName;
    private BigDecimal invoiceAmount;
    private BigDecimal currentBalance;
    private BigDecimal interestAccrued;
    private LocalDate floorDate;
    private LocalDate curtailmentDate;
    private LocalDate payoffDate;
    private String fpStatus;

    // --- Computed display fields ---
    private String statusName;          // Active, Paid Off
    private Integer daysOnFloor;
    private Integer daysToCurtailment;
    private String vehicleDescription;  // "2025 TOY CAMRY"
}
