package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.Commission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface CommissionRepository extends JpaRepository<Commission, Integer> {

    List<Commission> findByDealerCodeAndPayPeriodOrderBySalespersonId(String dealerCode, String payPeriod);

    List<Commission> findBySalespersonIdAndPayPeriod(String salespersonId, String payPeriod);

    List<Commission> findByDealNumber(String dealNumber);

    List<Commission> findByDealerCodeAndPaidFlag(String dealerCode, String paidFlag);

    @Query("SELECT SUM(c.commAmount) FROM Commission c WHERE c.dealerCode = :dealerCode AND c.payPeriod = :payPeriod")
    BigDecimal sumCommAmountByDealerCodeAndPayPeriod(@Param("dealerCode") String dealerCode,
                                                     @Param("payPeriod") String payPeriod);
}
