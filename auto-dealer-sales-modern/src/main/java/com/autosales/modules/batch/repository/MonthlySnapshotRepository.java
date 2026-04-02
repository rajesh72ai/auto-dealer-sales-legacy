package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.MonthlySnapshot;
import com.autosales.modules.batch.entity.MonthlySnapshotId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MonthlySnapshotRepository extends JpaRepository<MonthlySnapshot, MonthlySnapshotId> {

    List<MonthlySnapshot> findByDealerCodeOrderBySnapshotMonthDesc(String dealerCode);

    List<MonthlySnapshot> findBySnapshotMonth(String snapshotMonth);

    Optional<MonthlySnapshot> findBySnapshotMonthAndDealerCode(String snapshotMonth, String dealerCode);

    List<MonthlySnapshot> findByDealerCodeAndSnapshotMonthBetweenOrderBySnapshotMonthDesc(
            String dealerCode, String startMonth, String endMonth);
}
