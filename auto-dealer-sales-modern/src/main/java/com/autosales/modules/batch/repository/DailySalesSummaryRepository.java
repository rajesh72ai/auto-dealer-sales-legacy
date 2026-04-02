package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.DailySalesSummary;
import com.autosales.modules.batch.entity.DailySalesSummaryId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface DailySalesSummaryRepository extends JpaRepository<DailySalesSummary, DailySalesSummaryId> {

    List<DailySalesSummary> findByDealerCodeAndSummaryDateBetweenOrderBySummaryDateDesc(
            String dealerCode, LocalDate startDate, LocalDate endDate);

    List<DailySalesSummary> findBySummaryDate(LocalDate summaryDate);

    List<DailySalesSummary> findByDealerCodeOrderBySummaryDateDesc(String dealerCode);

    void deleteBySummaryDateBefore(LocalDate cutoffDate);
}
