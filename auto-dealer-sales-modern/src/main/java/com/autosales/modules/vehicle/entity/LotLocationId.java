package com.autosales.modules.vehicle.entity;

import lombok.*;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LotLocationId implements Serializable {

    private String dealerCode;
    private String locationCode;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        LotLocationId that = (LotLocationId) o;
        return Objects.equals(dealerCode, that.dealerCode)
                && Objects.equals(locationCode, that.locationCode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(dealerCode, locationCode);
    }
}
