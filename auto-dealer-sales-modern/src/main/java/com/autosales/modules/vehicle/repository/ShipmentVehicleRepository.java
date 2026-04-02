package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.ShipmentVehicle;
import com.autosales.modules.vehicle.entity.ShipmentVehicleId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ShipmentVehicleRepository extends JpaRepository<ShipmentVehicle, ShipmentVehicleId> {

    List<ShipmentVehicle> findByShipmentId(String shipmentId);

    Optional<ShipmentVehicle> findByVin(String vin);

    long countByShipmentId(String shipmentId);
}
