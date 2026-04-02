package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.ProductionOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ProductionOrderRepository extends JpaRepository<ProductionOrder, String> {

    Optional<ProductionOrder> findByVin(String vin);

    Page<ProductionOrder> findByBuildStatus(String buildStatus, Pageable pageable);

    Page<ProductionOrder> findByAllocatedDealer(String allocatedDealer, Pageable pageable);

    @Query("SELECT p FROM ProductionOrder p WHERE " +
            "(:status IS NULL OR p.buildStatus = :status) " +
            "AND (:plantCode IS NULL OR p.plantCode = :plantCode) " +
            "AND (:dealer IS NULL OR p.allocatedDealer = :dealer)")
    Page<ProductionOrder> searchOrders(
            @Param("status") String status,
            @Param("plantCode") String plantCode,
            @Param("dealer") String dealer,
            Pageable pageable);

    long countByBuildStatus(String buildStatus);

    List<ProductionOrder> findByAllocatedDealerIsNullAndBuildStatusIn(List<String> statuses);
}
