package com.autosales.modules.vehicle.repository;

import com.autosales.modules.vehicle.entity.StockSnapshot;
import com.autosales.modules.vehicle.entity.StockSnapshotId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface StockSnapshotRepository extends JpaRepository<StockSnapshot, StockSnapshotId> {

    List<StockSnapshot> findByDealerCode(String dealerCode);

    List<StockSnapshot> findByDealerCodeAndSnapshotDate(String dealerCode, LocalDate snapshotDate);

    Page<StockSnapshot> findByDealerCodeAndSnapshotDateBetween(
            String dealerCode, LocalDate from, LocalDate to, Pageable pageable);

    void deleteByDealerCodeAndSnapshotDate(String dealerCode, LocalDate snapshotDate);

    void deleteBySnapshotDate(LocalDate snapshotDate);
}
