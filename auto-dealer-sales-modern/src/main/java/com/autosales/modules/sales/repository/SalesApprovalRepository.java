package com.autosales.modules.sales.repository;

import com.autosales.modules.sales.entity.SalesApproval;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SalesApprovalRepository extends JpaRepository<SalesApproval, Integer> {

    List<SalesApproval> findByDealNumber(String dealNumber);

    List<SalesApproval> findByApproverId(String approverId);
}
