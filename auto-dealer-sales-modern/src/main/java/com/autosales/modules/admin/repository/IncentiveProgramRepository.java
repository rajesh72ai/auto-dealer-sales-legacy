package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.IncentiveProgram;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncentiveProgramRepository extends JpaRepository<IncentiveProgram, String> {

    List<IncentiveProgram> findByActiveFlag(String activeFlag);

    List<IncentiveProgram> findByModelYearAndMakeCode(Short modelYear, String makeCode);

    Page<IncentiveProgram> findByActiveFlag(String activeFlag, Pageable pageable);

    Page<IncentiveProgram> findByIncentiveType(String type, Pageable pageable);

    Page<IncentiveProgram> findByIncentiveTypeAndActiveFlag(String type, String activeFlag, Pageable pageable);
}
