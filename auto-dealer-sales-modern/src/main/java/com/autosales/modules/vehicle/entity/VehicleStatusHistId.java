package com.autosales.modules.vehicle.entity;

import lombok.*;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VehicleStatusHistId implements Serializable {

    private String vin;
    private Integer statusSeq;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        VehicleStatusHistId that = (VehicleStatusHistId) o;
        return Objects.equals(vin, that.vin)
                && Objects.equals(statusSeq, that.statusSeq);
    }

    @Override
    public int hashCode() {
        return Objects.hash(vin, statusSeq);
    }
}
