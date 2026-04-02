package com.autosales.modules.floorplan.repository;

import com.autosales.modules.floorplan.entity.FloorPlanInterest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FloorPlanInterestRepository extends JpaRepository<FloorPlanInterest, Integer> {

    List<FloorPlanInterest> findByFloorPlanIdOrderByCalcDateDesc(Integer floorPlanId);

    Optional<FloorPlanInterest> findTopByFloorPlanIdOrderByCalcDateDesc(Integer floorPlanId);
}
