package com.autosales.modules.floorplan.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "floor_plan_interest")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FloorPlanInterest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "interest_id")
    private Integer interestId;

    @Column(name = "floor_plan_id", nullable = false)
    private Integer floorPlanId;

    @Column(name = "calc_date", nullable = false)
    private LocalDate calcDate;

    @Column(name = "principal_bal", nullable = false)
    private BigDecimal principalBal;

    @Column(name = "rate_applied", nullable = false)
    private BigDecimal rateApplied;

    @Column(name = "daily_interest", nullable = false)
    private BigDecimal dailyInterest;

    @Column(name = "cumulative_int", nullable = false)
    private BigDecimal cumulativeInt;
}
