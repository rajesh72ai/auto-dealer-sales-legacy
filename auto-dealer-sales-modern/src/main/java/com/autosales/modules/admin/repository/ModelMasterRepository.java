package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ModelMasterRepository extends JpaRepository<ModelMaster, ModelMasterId> {

    List<ModelMaster> findByModelYear(Short modelYear);

    List<ModelMaster> findByModelYearAndMakeCode(Short modelYear, String makeCode);

    List<ModelMaster> findByActiveFlag(String activeFlag);

    Page<ModelMaster> findByMakeCode(String makeCode, Pageable pageable);

    Page<ModelMaster> findByModelYear(Short modelYear, Pageable pageable);

    Page<ModelMaster> findByModelYearAndMakeCode(Short modelYear, String makeCode, Pageable pageable);
}
