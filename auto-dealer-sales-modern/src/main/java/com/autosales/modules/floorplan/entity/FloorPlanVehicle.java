package com.autosales.modules.floorplan.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "floor_plan_vehicle")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FloorPlanVehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "floor_plan_id")
    private Integer floorPlanId;

    @Column(name = "vin", nullable = false)
    private String vin;

    @Column(name = "dealer_code", nullable = false)
    private String dealerCode;

    @Column(name = "lender_id", nullable = false)
    private String lenderId;

    @Column(name = "invoice_amount", nullable = false)
    private BigDecimal invoiceAmount;

    @Column(name = "current_balance", nullable = false)
    private BigDecimal currentBalance;

    @Column(name = "interest_accrued", nullable = false)
    private BigDecimal interestAccrued;

    @Column(name = "floor_date", nullable = false)
    private LocalDate floorDate;

    @Column(name = "curtailment_date")
    private LocalDate curtailmentDate;

    @Column(name = "payoff_date")
    private LocalDate payoffDate;

    @Column(name = "fp_status", nullable = false)
    private String fpStatus;

    @Column(name = "days_on_floor", nullable = false)
    private Short daysOnFloor;

    @Column(name = "last_interest_dt")
    private LocalDate lastInterestDt;
}
