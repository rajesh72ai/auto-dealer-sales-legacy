package com.autosales.modules.vehicle.entity;

import lombok.*;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShipmentVehicleId implements Serializable {

    private String shipmentId;
    private String vin;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ShipmentVehicleId that = (ShipmentVehicleId) o;
        return Objects.equals(shipmentId, that.shipmentId)
                && Objects.equals(vin, that.vin);
    }

    @Override
    public int hashCode() {
        return Objects.hash(shipmentId, vin);
    }
}
