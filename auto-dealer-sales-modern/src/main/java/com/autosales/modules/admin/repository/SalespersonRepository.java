package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.Salesperson;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SalespersonRepository extends JpaRepository<Salesperson, String> {

    List<Salesperson> findByDealer_DealerCode(String dealerCode);

    List<Salesperson> findByDealer_DealerCodeAndActiveFlag(String dealerCode, String activeFlag);

    Page<Salesperson> findByDealer_DealerCode(String dealerCode, Pageable pageable);

    Page<Salesperson> findByDealer_DealerCodeAndActiveFlag(String dealerCode, String activeFlag, Pageable pageable);
}
