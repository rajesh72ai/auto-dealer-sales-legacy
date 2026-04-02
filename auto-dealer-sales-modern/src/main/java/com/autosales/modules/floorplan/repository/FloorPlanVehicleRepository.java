package com.autosales.modules.floorplan.repository;

import com.autosales.modules.floorplan.entity.FloorPlanVehicle;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface FloorPlanVehicleRepository extends JpaRepository<FloorPlanVehicle, Integer> {

    List<FloorPlanVehicle> findByVin(String vin);

    List<FloorPlanVehicle> findByDealerCodeAndFpStatus(String dealerCode, String fpStatus);

    Page<FloorPlanVehicle> findByDealerCode(String dealerCode, Pageable pageable);

    Page<FloorPlanVehicle> findByDealerCodeAndFpStatus(String dealerCode, String fpStatus, Pageable pageable);

    Optional<FloorPlanVehicle> findByVinAndFpStatus(String vin, String fpStatus);

    List<FloorPlanVehicle> findByFpStatus(String fpStatus);

    List<FloorPlanVehicle> findByDealerCodeAndFpStatusOrderByFloorDateDesc(String dealerCode, String fpStatus);

    @Query("SELECT COUNT(v) FROM FloorPlanVehicle v WHERE v.dealerCode = :dealerCode AND v.fpStatus = :fpStatus")
    long countByDealerCodeAndFpStatus(@Param("dealerCode") String dealerCode, @Param("fpStatus") String fpStatus);

    @Query("SELECT COALESCE(SUM(v.currentBalance), 0) FROM FloorPlanVehicle v WHERE v.dealerCode = :dealerCode AND v.fpStatus = :fpStatus")
    BigDecimal sumCurrentBalanceByDealerCodeAndFpStatus(@Param("dealerCode") String dealerCode, @Param("fpStatus") String fpStatus);

    @Query("SELECT v FROM FloorPlanVehicle v WHERE v.curtailmentDate <= :cutoffDate AND v.fpStatus = :fpStatus")
    List<FloorPlanVehicle> findByCurtailmentDateWithinDays(@Param("cutoffDate") LocalDate cutoffDate, @Param("fpStatus") String fpStatus);
}
