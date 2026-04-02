package com.autosales.modules.sales.repository;

import com.autosales.modules.sales.entity.IncentiveApplied;
import com.autosales.modules.sales.entity.IncentiveAppliedId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncentiveAppliedRepository extends JpaRepository<IncentiveApplied, IncentiveAppliedId> {

    List<IncentiveApplied> findByDealNumber(String dealNumber);

    List<IncentiveApplied> findByIncentiveId(String incentiveId);
}
