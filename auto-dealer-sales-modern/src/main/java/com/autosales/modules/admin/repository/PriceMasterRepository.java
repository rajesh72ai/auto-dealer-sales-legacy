package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.PriceMaster;
import com.autosales.modules.admin.entity.PriceMasterId;
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
public interface PriceMasterRepository extends JpaRepository<PriceMaster, PriceMasterId> {

    List<PriceMaster> findByModelYearAndMakeCodeAndModelCode(Short modelYear, String makeCode, String modelCode);

    Page<PriceMaster> findByModelYearAndMakeCode(Short year, String make, Pageable pageable);

    List<PriceMaster> findTop5ByModelYearAndMakeCodeAndModelCodeOrderByEffectiveDateDesc(Short year, String make, String model);

    @Query("SELECT p FROM PriceMaster p WHERE p.modelYear = :year AND p.makeCode = :make AND p.modelCode = :model " +
           "AND p.effectiveDate <= :asOf AND (p.expiryDate IS NULL OR p.expiryDate >= :asOf) " +
           "ORDER BY p.effectiveDate DESC")
    Optional<PriceMaster> findCurrentEffective(@Param("year") Short year, @Param("make") String make,
                                                @Param("model") String model, @Param("asOf") LocalDate asOf);
}
