package com.autosales.modules.finance.repository;

import com.autosales.modules.finance.entity.FiDealProduct;
import com.autosales.modules.finance.entity.FiDealProductId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FiDealProductRepository extends JpaRepository<FiDealProduct, FiDealProductId> {

    List<FiDealProduct> findByDealNumber(String dealNumber);

    int countByDealNumber(String dealNumber);
}
