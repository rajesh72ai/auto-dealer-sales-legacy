package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.Shipment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ShipmentRepository extends JpaRepository<Shipment, String> {

    Page<Shipment> findByDestDealer(String destDealer, Pageable pageable);

    Page<Shipment> findByShipmentStatus(String status, Pageable pageable);

    @Query("SELECT s FROM Shipment s WHERE " +
            "(:status IS NULL OR s.shipmentStatus = :status) " +
            "AND (:dealer IS NULL OR s.destDealer = :dealer) " +
            "AND (:carrier IS NULL OR s.carrierCode = :carrier)")
    Page<Shipment> searchShipments(
            @Param("status") String status,
            @Param("dealer") String dealer,
            @Param("carrier") String carrier,
            Pageable pageable);
}
