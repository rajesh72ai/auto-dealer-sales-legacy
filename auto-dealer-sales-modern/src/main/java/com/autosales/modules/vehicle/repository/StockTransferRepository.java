package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.StockTransfer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface StockTransferRepository extends JpaRepository<StockTransfer, Integer> {

    @Query("SELECT t FROM StockTransfer t WHERE t.fromDealer = :dealer OR t.toDealer = :dealer")
    Page<StockTransfer> findByDealerInvolved(@Param("dealer") String dealer, Pageable pageable);

    List<StockTransfer> findByTransferStatus(String status);

    @Query("SELECT t FROM StockTransfer t WHERE (t.fromDealer = :dealer OR t.toDealer = :dealer) " +
            "AND (:status IS NULL OR t.transferStatus = :status)")
    Page<StockTransfer> findByDealerAndStatus(
            @Param("dealer") String dealer, @Param("status") String status, Pageable pageable);

    List<StockTransfer> findByVinAndTransferStatus(String vin, String status);
}
