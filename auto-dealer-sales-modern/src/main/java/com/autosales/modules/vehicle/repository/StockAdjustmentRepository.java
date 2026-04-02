package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.StockAdjustment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface StockAdjustmentRepository extends JpaRepository<StockAdjustment, Integer> {

    Page<StockAdjustment> findByDealerCode(String dealerCode, Pageable pageable);

    List<StockAdjustment> findByDealerCodeAndAdjustedTsBetween(
            String dealerCode, LocalDateTime from, LocalDateTime to);

    List<StockAdjustment> findByVin(String vin);
}
