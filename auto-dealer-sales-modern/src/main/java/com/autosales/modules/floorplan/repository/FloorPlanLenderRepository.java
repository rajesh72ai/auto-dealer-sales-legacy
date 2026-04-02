package com.autosales.modules.floorplan.repository;

import com.autosales.modules.floorplan.entity.FloorPlanLender;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FloorPlanLenderRepository extends JpaRepository<FloorPlanLender, String> {

    Optional<FloorPlanLender> findByLenderId(String lenderId);

    List<FloorPlanLender> findAllByOrderByLenderNameAsc();
}
