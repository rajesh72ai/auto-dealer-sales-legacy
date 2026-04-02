package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.CommissionAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommissionAuditRepository extends JpaRepository<CommissionAudit, Integer> {

    List<CommissionAudit> findByDealNumberOrderByAuditTsDesc(String dealNumber);

    List<CommissionAudit> findByEntityTypeOrderByAuditTsDesc(String entityType);
}
