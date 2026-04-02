package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.PriceSchedule;
import com.autosales.modules.admin.entity.PriceScheduleId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PriceScheduleRepository extends JpaRepository<PriceSchedule, PriceScheduleId> {

    List<PriceSchedule> findByModelYearAndMakeCodeAndModelCode(Short modelYear, String makeCode, String modelCode);

    List<PriceSchedule> findByScheduleType(String scheduleType);
}
