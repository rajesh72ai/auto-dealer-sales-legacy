package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.RecallVehicle;
import com.autosales.modules.registration.entity.RecallVehicleId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecallVehicleRepository extends JpaRepository<RecallVehicle, RecallVehicleId> {

    List<RecallVehicle> findByRecallId(String recallId);

    Page<RecallVehicle> findByRecallId(String recallId, Pageable pageable);

    Page<RecallVehicle> findByRecallIdAndRecallStatus(String recallId, String recallStatus, Pageable pageable);

    List<RecallVehicle> findByVin(String vin);

    List<RecallVehicle> findByDealerCode(String dealerCode);

    long countByRecallIdAndRecallStatus(String recallId, String recallStatus);
}
