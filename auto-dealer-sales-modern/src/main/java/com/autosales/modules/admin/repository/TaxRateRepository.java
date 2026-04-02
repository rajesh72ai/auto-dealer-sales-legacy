package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.TaxRate;
import com.autosales.modules.admin.entity.TaxRateId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface TaxRateRepository extends JpaRepository<TaxRate, TaxRateId> {

    List<TaxRate> findByStateCode(String stateCode);

    List<TaxRate> findByStateCodeAndCountyCode(String stateCode, String countyCode);

    Page<TaxRate> findByStateCode(String stateCode, Pageable pageable);

    @Query("SELECT t FROM TaxRate t WHERE t.stateCode = :state AND t.countyCode = :county " +
           "AND t.cityCode = :city AND t.effectiveDate <= :asOf AND (t.expiryDate IS NULL OR t.expiryDate >= :asOf) " +
           "ORDER BY t.effectiveDate DESC")
    Optional<TaxRate> findCurrentEffective(@Param("state") String state, @Param("county") String county,
                                            @Param("city") String city, @Param("asOf") LocalDate asOf);
}
