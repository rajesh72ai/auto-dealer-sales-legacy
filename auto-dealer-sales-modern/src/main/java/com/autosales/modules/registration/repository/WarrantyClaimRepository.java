package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.WarrantyClaim;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface WarrantyClaimRepository extends JpaRepository<WarrantyClaim, String> {

    List<WarrantyClaim> findByDealerCodeAndClaimStatus(String dealerCode, String claimStatus);

    List<WarrantyClaim> findByVin(String vin);

    Page<WarrantyClaim> findByDealerCode(String dealerCode, Pageable pageable);

    Page<WarrantyClaim> findByDealerCodeAndClaimStatus(String dealerCode, String claimStatus, Pageable pageable);

    List<WarrantyClaim> findByDealerCodeAndClaimDateBetween(String dealerCode, LocalDate fromDate, LocalDate toDate);

    @Query("SELECT wc FROM WarrantyClaim wc WHERE wc.dealerCode = :dealerCode " +
           "AND (:fromDate IS NULL OR wc.claimDate >= :fromDate) " +
           "AND (:toDate IS NULL OR wc.claimDate <= :toDate)")
    List<WarrantyClaim> findClaimsForReport(String dealerCode, LocalDate fromDate, LocalDate toDate);
}
