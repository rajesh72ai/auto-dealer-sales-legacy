package com.autosales.modules.vehicle.entity;

import lombok.*;

import java.io.Serializable;
import java.time.LocalDate;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StockSnapshotId implements Serializable {

    private LocalDate snapshotDate;
    private String dealerCode;
    private Short modelYear;
    private String makeCode;
    private String modelCode;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        StockSnapshotId that = (StockSnapshotId) o;
        return Objects.equals(snapshotDate, that.snapshotDate)
                && Objects.equals(dealerCode, that.dealerCode)
                && Objects.equals(modelYear, that.modelYear)
                && Objects.equals(makeCode, that.makeCode)
                && Objects.equals(modelCode, that.modelCode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(snapshotDate, dealerCode, modelYear, makeCode, modelCode);
    }
}
