package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.LotLocation;
import com.autosales.modules.vehicle.entity.LotLocationId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LotLocationRepository extends JpaRepository<LotLocation, LotLocationId> {

    List<LotLocation> findByDealerCode(String dealerCode);

    List<LotLocation> findByDealerCodeAndActiveFlag(String dealerCode, String activeFlag);
}
