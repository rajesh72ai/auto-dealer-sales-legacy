package com.autosales.modules.finance.repository;

import com.autosales.modules.finance.entity.FinanceProduct;
import com.autosales.modules.finance.entity.FinanceProductId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FinanceProductRepository extends JpaRepository<FinanceProduct, FinanceProductId> {

    List<FinanceProduct> findByDealNumber(String dealNumber);

    int countByDealNumber(String dealNumber);

    void deleteByDealNumber(String dealNumber);
}
