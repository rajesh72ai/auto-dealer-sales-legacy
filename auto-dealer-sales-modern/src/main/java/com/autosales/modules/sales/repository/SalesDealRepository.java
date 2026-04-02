package com.autosales.modules.sales.repository;

import com.autosales.modules.sales.entity.SalesDeal;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface SalesDealRepository extends JpaRepository<SalesDeal, String> {

    List<SalesDeal> findByDealerCodeAndDealDateBetween(String dealerCode, LocalDate startDate, LocalDate endDate);

    Optional<SalesDeal> findByVin(String vin);

    List<SalesDeal> findByDealerCodeAndDealStatus(String dealerCode, String dealStatus);

    List<SalesDeal> findByCustomerId(Integer customerId);

    List<SalesDeal> findBySalespersonId(String salespersonId);

    List<SalesDeal> findByCustomerIdOrderByDealDateDesc(Integer customerId);

    Page<SalesDeal> findByDealerCode(String dealerCode, Pageable pageable);

    Page<SalesDeal> findByDealerCodeAndDealStatus(String dealerCode, String status, Pageable pageable);

    List<SalesDeal> findByDealerCodeAndDealStatusIn(String dealerCode, List<String> statuses);

    Page<SalesDeal> findByDealerCodeAndDealStatusIn(String dealerCode, List<String> statuses, Pageable pageable);
}
