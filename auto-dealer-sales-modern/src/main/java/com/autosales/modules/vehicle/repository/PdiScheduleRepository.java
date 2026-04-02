package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.PdiSchedule;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PdiScheduleRepository extends JpaRepository<PdiSchedule, Integer> {

    Page<PdiSchedule> findByDealerCode(String dealerCode, Pageable pageable);

    Page<PdiSchedule> findByDealerCodeAndPdiStatus(String dealerCode, String status, Pageable pageable);

    Optional<PdiSchedule> findTopByVinOrderByPdiIdDesc(String vin);

    List<PdiSchedule> findByVin(String vin);
}
