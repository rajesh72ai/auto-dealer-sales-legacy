package com.autosales.modules.finance.repository;

import com.autosales.modules.finance.entity.FinanceApp;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FinanceAppRepository extends JpaRepository<FinanceApp, String> {

    Page<FinanceApp> findByDealNumber(String dealNumber, Pageable pageable);

    List<FinanceApp> findByDealNumber(String dealNumber);

    Optional<FinanceApp> findByFinanceId(String financeId);

    Page<FinanceApp> findByAppStatus(String appStatus, Pageable pageable);

    Page<FinanceApp> findByFinanceType(String financeType, Pageable pageable);

    @Query("SELECT fa FROM FinanceApp fa WHERE fa.dealNumber LIKE %:searchTerm% OR LOWER(fa.lenderName) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<FinanceApp> searchByDealNumberOrLenderName(@Param("searchTerm") String searchTerm, Pageable pageable);

    Optional<FinanceApp> findByDealNumberAndFinanceType(String dealNumber, String financeType);
}
