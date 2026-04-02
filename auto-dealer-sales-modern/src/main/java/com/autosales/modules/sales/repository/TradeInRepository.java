package com.autosales.modules.sales.repository;

import com.autosales.modules.sales.entity.TradeIn;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TradeInRepository extends JpaRepository<TradeIn, Integer> {

    List<TradeIn> findBySalesDeal_DealNumber(String dealNumber);
}
