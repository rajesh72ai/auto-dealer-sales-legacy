package com.autosales.modules.sales.repository;

import com.autosales.modules.sales.entity.DealLineItem;
import com.autosales.modules.sales.entity.DealLineItemId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DealLineItemRepository extends JpaRepository<DealLineItem, DealLineItemId> {

    List<DealLineItem> findByDealNumber(String dealNumber);
}
