package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.VehicleStatusHist;
import com.autosales.modules.vehicle.entity.VehicleStatusHistId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VehicleStatusHistRepository extends JpaRepository<VehicleStatusHist, VehicleStatusHistId> {

    List<VehicleStatusHist> findByVinOrderByStatusSeqDesc(String vin);

    Optional<VehicleStatusHist> findTopByVinOrderByStatusSeqDesc(String vin);
}
