package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.Dealer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DealerRepository extends JpaRepository<Dealer, String> {

    List<Dealer> findByRegionCode(String regionCode);

    List<Dealer> findByActiveFlagOrderByDealerName(String activeFlag);

    Page<Dealer> findByRegionCode(String regionCode, Pageable pageable);

    Page<Dealer> findByActiveFlag(String activeFlag, Pageable pageable);

    Page<Dealer> findByRegionCodeAndActiveFlag(String regionCode, String activeFlag, Pageable pageable);
}
