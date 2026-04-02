package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.Vehicle;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface VehicleRepository extends JpaRepository<Vehicle, String> {

    List<Vehicle> findByDealerCodeAndVehicleStatus(String dealerCode, String vehicleStatus);

    Optional<Vehicle> findByStockNumber(String stockNumber);

    Page<Vehicle> findByDealerCode(String dealerCode, Pageable pageable);

    Page<Vehicle> findByDealerCodeAndVehicleStatus(String dealerCode, String vehicleStatus, Pageable pageable);

    Page<Vehicle> findByDealerCodeAndVehicleStatusIn(String dealerCode, List<String> statuses, Pageable pageable);

    @Query("SELECT v FROM Vehicle v WHERE v.dealerCode = :dealerCode " +
            "AND (:status IS NULL OR v.vehicleStatus = :status) " +
            "AND (:modelYear IS NULL OR v.modelYear = :modelYear) " +
            "AND (:makeCode IS NULL OR v.makeCode = :makeCode) " +
            "AND (:modelCode IS NULL OR v.modelCode = :modelCode) " +
            "AND (:color IS NULL OR v.exteriorColor = :color)")
    Page<Vehicle> searchVehicles(
            @Param("dealerCode") String dealerCode,
            @Param("status") String status,
            @Param("modelYear") Short modelYear,
            @Param("makeCode") String makeCode,
            @Param("modelCode") String modelCode,
            @Param("color") String color,
            Pageable pageable);

    List<Vehicle> findByDealerCodeAndVehicleStatusInAndReceiveDateIsNotNull(
            String dealerCode, List<String> statuses);

    long countByDealerCodeAndVehicleStatus(String dealerCode, String vehicleStatus);
}
