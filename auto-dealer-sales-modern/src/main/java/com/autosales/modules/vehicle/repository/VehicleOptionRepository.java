package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.VehicleOption;
import com.autosales.modules.vehicle.entity.VehicleOptionId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VehicleOptionRepository extends JpaRepository<VehicleOption, VehicleOptionId> {

    List<VehicleOption> findByVin(String vin);

    List<VehicleOption> findByVinAndInstalledFlag(String vin, String installedFlag);
}
