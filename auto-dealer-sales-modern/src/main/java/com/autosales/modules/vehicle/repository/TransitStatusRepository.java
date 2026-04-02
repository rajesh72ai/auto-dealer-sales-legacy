package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.TransitStatus;
import com.autosales.modules.vehicle.entity.TransitStatusId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TransitStatusRepository extends JpaRepository<TransitStatus, TransitStatusId> {

    List<TransitStatus> findByVinOrderByStatusSeqAsc(String vin);

    List<TransitStatus> findByVinOrderByStatusSeqDesc(String vin);

    Optional<TransitStatus> findTopByVinOrderByStatusSeqDesc(String vin);
}
