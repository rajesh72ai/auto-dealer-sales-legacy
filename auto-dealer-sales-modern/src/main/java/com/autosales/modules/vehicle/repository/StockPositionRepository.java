package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.StockPositionId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StockPositionRepository extends JpaRepository<StockPosition, StockPositionId> {

    List<StockPosition> findByDealerCode(String dealerCode);

    List<StockPosition> findByDealerCodeAndModelYear(String dealerCode, Short modelYear);

    List<StockPosition> findByDealerCodeAndMakeCode(String dealerCode, String makeCode);
}
