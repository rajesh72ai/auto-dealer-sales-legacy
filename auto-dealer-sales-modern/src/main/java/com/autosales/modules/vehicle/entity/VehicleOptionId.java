package com.autosales.modules.vehicle.entity;

import lombok.*;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VehicleOptionId implements Serializable {

    private String vin;
    private String optionCode;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        VehicleOptionId that = (VehicleOptionId) o;
        return Objects.equals(vin, that.vin)
                && Objects.equals(optionCode, that.optionCode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(vin, optionCode);
    }
}
